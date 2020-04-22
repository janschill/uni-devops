# frozen_string_literal: true

require 'roda'
require './models'
require './controllers/user_controller'
require './controllers/login_controller'
require './controllers/register_controller'
require './controllers/message_controller'
require 'prometheus/client'
require 'usagewatch_ext'
require 'logger'
require 'yaml'
require 'cgi'

module MiniTwit
  # Main class for the application routing
  class App < Roda
    plugin :assets, css: ['style.css']
    plugin :render
    plugin :hooks
    plugin :sessions,
           key: ENV['SESSION_KEY'],
           secret: ENV['SESSION_RAND']

    log_config = YAML.load_file('config/log.yml')
    logger = Logger.new(log_config['app']['filepath'], 10, 1_024_000)
    logger.info('Initializing APP')

    usw = Usagewatch

    prometheus = Prometheus::Client.registry
    http_requests_counter = prometheus.counter(:minitwit_app_http_requests, docstring: 'A counter of HTTP requests made to enpoints of the app', labels: %i[method endpoint])
    cpu_load_gauge = prometheus.gauge(:minitwit_app_cpu_load, docstring: 'A gauge of CPU load')
    http_response_duration_histogram = prometheus.histogram(:minitwit_app_http_response_duration, docstring: 'A histogram tracking http response time', labels: %i[method endpoint])

    user = nil
    response_start_time = nil
    request_labels = nil

    before do
      response_start_time = Time.now
      user = session['user_id'].nil? ? nil : User.where(user_id: session['user_id']).first
      cpu_load_gauge.set(usw.uw_cpuused)
    end

    after do
      unless request_labels.nil?
        http_requests_counter.increment(labels: request_labels)
        http_response_duration_histogram.observe(Time.now - response_start_time, labels: request_labels)
      end
    end

    route do |r|
      r.assets

      begin
        @error = nil

        r.root do
          request_labels = { endpoint: r.path, method: r.request_method }
          r.redirect('public') if user.nil?
          @options = {
            'page_title' => 'My timeline',
            'request_endpoint' => 'timeline'
          }
          @offset = check_offset(r.params['offset'])
          @messages = Message.messages_by_user_id_and_followers(user.user_id)
          @user = user
          view('timeline')
        end

        r.get 'public' do
          request_labels = { endpoint: r.path, method: r.request_method }
          @options = {
            'page_title' => 'Public timeline'
          }
          @user = user
          @offset = check_offset(r.params['offset'])
          @messages = Message.latest_messages(@offset)
          view('timeline')
        end

        r.post 'add_message' do
          request_labels = { endpoint: r.path, method: r.request_method }
          r.redirect('/') if session['user_id'].nil?
          message_controller = MessageController.new(r, user)
          message = message_controller.add_message
          logger.info('User ' + session['user_id'].to_s + ' posted Message ' + message.message_id.to_s) unless message.nil?
          r.redirect('/')
        end

        r.on 'login' do
          request_labels = { endpoint: r.path, method: r.request_method }
          @options = { 'page_title' => 'Login' }

          r.get do
            request.redirect('/') unless user.nil?
            view('login')
          end

          r.post do
            login_controller = LoginController.new(r)
            error, user = login_controller.attempt_login_user
            if error.nil?
              logger.info('User ' + user.user_id.to_s + ' logged in')
              session['user_id'] = user.user_id
              r.redirect('/')
            else
              @error = error
              view('login')
            end
          end
        end

        r.on 'register' do
          request_labels = { endpoint: r.path, method: r.request_method }
          register_controller = RegisterController.new(r)
          @options = { 'page_title' => 'Register' }

          r.get do
            request.redirect('/') unless user.nil?
            view('register')
          end

          r.post do
            error, user = register_controller.register_user
            if error.nil? && user.nil?
              r.redirect('/')
            elsif user.nil?
              @error = error
              view('register')
            else
              logger.info('New user with id ' + user.user_id.to_s + ' registered')
              session['user_id'] = user.user_id
              r.redirect('/')
            end
          end
        end

        r.get 'logout' do
          request_labels = { endpoint: r.path, method: r.request_method }
          logger.info('User ' + session['user_id'].to_s + ' logged out')
          session.clear
          r.redirect('/')
        end

        r.on 'user' do
          r.on Integer do |target_user_id|
            request_labels = { endpoint: '/user/:target_user_id' + r.remaining_path, method: r.request_method }
            user_controller = UserController.new(user, target_user_id)
            r.redirect('/') if user_controller.target_user.nil?

            r.on 'follow' do
              if user_controller.attempt_follow
                logger.info('User ' + session['user_id'].to_s + ' started following User ' + target_user_id.to_s)
                r.redirect("/user/#{user_controller.target_user.user_id}")
              else
                r.redirect('/')
              end
            end

            r.on 'unfollow' do
              if user_controller.attempt_unfollow
                logger.info('User ' + session['user_id'].to_s + ' unfollowed User ' + target_user_id.to_s)
                r.redirect("/user/#{user_controller.target_user.user_id}")
              else
                r.redirect('/')
              end
            end

            @options = {
              'page_title' => "#{user_controller.target_user.username}'s timeline",
              'request_endpoint' => 'user_timeline'
            }

            @offset = check_offset(r.params['offset'])
            @user = user
            @target_user = user_controller.target_user
            @is_follower = user_controller.check_if_following_target_user
            @messages = user_controller.messages_from_target_user(@offset)
            view('timeline')
          end
        end
      rescue StandardError => e
        msg = 'Exception raised by request ' + r.request_method.to_s + ' ' + r.path.to_s
        if r.post?
          r.params['password'] = '_REDACTED_' unless r.params['password'].nil?
          msg += ' ' + r.params.to_s
        end
        msg += ':'
        logger.error(msg.gsub(/[\r\n]/, ' '))
        logger.error(e.message.gsub(/[\r\n]/, ' '))
        logger.error(e.backtrace.join(', ') .gsub(/[\r\n]/, ' '))
        raise e # let rack handle the exception
      end
    end

    private

    def check_offset(offset_from_request)
      offset = 0
      unless offset_from_request.nil? || offset_from_request == ''
        offset_parsed = Integer(offset_from_request)
        offset = offset_parsed if offset_parsed.positive?
      end
      offset
    end
  end
end
