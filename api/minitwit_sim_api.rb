# frozen_string_literal: true

require 'roda'
require './models'
require 'bcrypt'
require 'json'
require 'cgi'
require 'prometheus/client'
require 'logger'
require 'yaml'

module MiniTwit
  class SimAPI < Roda
    plugin :hooks

    log_config = YAML.load_file('config/log.yml')
    logger = Logger.new(log_config['api']['filepath'], 10, 1_024_000)
    logger.info('Initializing API')

    latest = 0
    response_start_time = nil

    prometheus = Prometheus::Client.registry
    http_requests_counter = prometheus.counter(:minitwit_api_http_requests, docstring: 'A counter of HTTP requests made to enpoints of the api', labels: %i[method endpoint])
    http_response_duration_histogram = prometheus.histogram(:minitwit_api_http_response_duration, docstring: 'A histogram tracking http response time', labels: %i[method endpoint])

    request_labels = nil

    before do
      response_start_time = Time.now
    end

    after do
      unless request_labels.nil?
        http_requests_counter.increment(labels: request_labels)
        http_response_duration_histogram.observe(Time.now - response_start_time, labels: request_labels)
      end
    end

    route do |r|
      body = nil

      begin
        r.get 'latest' do
          request_labels = { endpoint: r.path, method: r.request_method }
          return { 'latest' => latest }.to_json
        end

        body = JSON.parse(r.body.read) if r.post?

        try_latest = r.params['latest'].to_s
        latest = try_latest.to_i if try_latest != ''

        r.post 'register' do
          request_labels = { endpoint: r.path, method: r.request_method }
          error = nil
          username = body['username']
          email = body['email']
          password = body['pwd']
          if username.nil?
            error = 'You have to enter a username'
          elsif email.nil? || !email.include?('@')
            error = 'You have to enter a valid email address'
          elsif password.nil?
            error = 'You have to enter a password'
          else
            user = User.where(username: username).first
            if !user.nil?
              error = 'The username is already taken'
            else
              user = User.new(
                email: email,
                username: username,
                password: BCrypt::Password.create(password)
              )
              user.save_changes
              logger.info('New user created: ' + user.values.to_s)
            end
          end
          
          if !error.nil?
            response.status = 400
            return error
          else
            response.status = 204
            return nil
          end
        end

        # check if request originated from the simulator (does not work for the test)

        authorization_code = r.env['HTTP_AUTHORIZATION']
        if authorization_code != 'Basic c2ltdWxhdG9yOnN1cGVyX3NhZmUh'
          response.status = 403
          return 'You are not authorized to use this resource!'
        end

        r.on 'msgs' do
          r.is do
            r.get do
              request_labels = { endpoint: r.path, method: r.request_method }
              no_msgs = r.params['no'].to_s
              no_msgs = no_msgs.empty? ? 100 : no_msgs.to_i # forgive me
              msgs = DB.fetch('SELECT * FROM messages m inner join users u ON m.user_id = u.user_id WHERE m.flagged = 0 ORDER BY m.pub_date DESC LIMIT ?;', no_msgs)
              filtered_msgs = []
              msgs.each do |msg|
                filtered_msg = {}
                filtered_msg['content'] = msg[:text]
                filtered_msg['pub_date'] = msg[:pub_date]
                filtered_msg['user'] = msg[:username]
                filtered_msgs.append(filtered_msg)
              end
              return filtered_msgs.to_json
            end
          end

          r.is String do |username|
            request_labels = { endpoint: '/msgs/:username' + r.remaining_path, method: r.request_method }
            username = CGI.unescape(username)
            user = User.where(username: username).first
            if user.nil?
              response.status = 400
              return 'No user with name ' + username
            end
            r.get do
              no_msgs = r.params['no'].to_s
              no_msgs = no_msgs.empty? ? 100 : no_msgs.to_i # forgive me
              msgs = DB.fetch('SELECT * FROM messages m inner join users u ON m.user_id = u.user_id WHERE m.flagged = 0 AND u.user_id = ? ORDER BY m.pub_date DESC LIMIT ?;', user.user_id, no_msgs)
              filtered_msgs = []
              msgs.each do |msg|
                filtered_msg = {}
                filtered_msg['content'] = msg[:text]
                filtered_msg['pub_date'] = msg[:pub_date]
                filtered_msg['user'] = msg[:username]
                filtered_msgs.append(filtered_msg)
              end
              return filtered_msgs.to_json
            end
            r.post do
              text = body['content']
              message = Message.new(
                text: text,
                user_id: user.user_id,
                pub_date: Time.now.to_i,
                flagged: false
              )
              message.save_changes
              logger.info('New message created: ' + message.values.to_s)
              response.status = 204
              return nil
            end
          end
        end

        r.on 'fllws' do
          r.is String do |username|
            request_labels = { endpoint: '/fllws/:username' + r.remaining_path, method: r.request_method }
            username = CGI.unescape(username)
            user = User.where(username: username).first
            if user.nil?
              response.status = 400
              return 'No user with name ' + username
            end

            no_followers = r.params['no'].to_s
            no_followers = no_followers.empty? ? 100 : no_followers.to_i # forgive me

            r.post do
              follow_username = body['follow'].to_s
              if follow_username != ''
                follow_user = User.where(username: follow_username).first
                if follow_user.nil?
                  response.status = 400
                  return 'follow user ' + follow_username + ' does not exist'
                end
                follower = Follower.new(
                  whom_id: follow_user.user_id,
                  who_id: user.user_id
                )
                follower.save_changes
                logger.info('New follower created: ' + follower.values.to_s)
                response.status = 204
                return nil
              end

              unfollow_username = body['unfollow'].to_s
              if unfollow_username != ''
                unfollow_user = User.where(username: unfollow_username).first
                if unfollow_user.nil?
                  response.status = 400
                  return 'unfollow user ' + unfollow_username + ' does not exist'
                end
              end
              Follower.where(
                whom_id: unfollow_user.user_id,
                who_id: user.user_id
              ).delete
              response.status = 204
              return nil
            end

            r.get do
              followers = DB.fetch("SELECT users.username FROM users
                              INNER JOIN followers ON followers.whom_id = users.user_id
                              WHERE followers.who_id=?
                              LIMIT ?", user.user_id, no_followers)

              follower_names = []
              followers.each do |follower|
                follower_names.append(follower[:username])
              end

              return { 'follows' => follower_names }.to_json
            end
          end
        end
      rescue Error => e
        msg = 'Exception raised by request ' + r.request_method.to_s + ' ' + r.path.to_s
        if r.post?
          body['password'] = '_REDACTED_' unless body['password'].nil?
          msg += ' ' + body.to_s
        end
        msg += ':'
        logger.error(msg.gsub(/[\r\n]/, ' '))
        logger.error(e.message.gsub(/[\r\n]/, ' '))
        logger.error(e.backtrace.join(', ').gsub(/[\r\n]/, ' '))
        raise e # let rack handle the exception
      end
    end
  end
end
