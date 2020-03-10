# frozen_string_literal: true

require 'roda'
require './models'
require './controllers/user_controller'
require './controllers/login_controller'
require './controllers/register_controller'
require './controllers/message_controller'

# rubocop:disable BlockLength, ClassLength
module MiniTwit
  # Main class for the application routing
  class App < Roda
    plugin :assets, css: ['style.css']
    plugin :render
    plugin :hooks
    plugin :sessions,
           key: ENV['SESSION_KEY'],
           secret: ENV['SESSION_RAND']

    user = nil

    before do
      user = nil
      unless session['user_id'].nil?
        user = User.where(user_id: session['user_id']).first
      end
    end

    route do |r|
      r.assets

      @error = nil

      r.root do
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
        @options = {
          'page_title' => 'Public timeline'
        }
        @user = user
        @offset = check_offset(r.params['offset'])
        @messages = Message.latest_messages(@offset)
        view('timeline')
      end

      # TODO: use 403 for redirect
      r.post 'add_message' do
        r.redirect('/') if session['user_id'].nil?
        message_controller = MessageController.new(r, user)
        message_controller.add_message()
        r.redirect('/')
      end

      r.on 'login' do
        @options = { 'page_title' => 'Login' }

        r.get do
          request.redirect('/') unless user.nil?
          view('login')
        end

        r.post do
          login_controller = LoginController.new(r)
          error, user = login_controller.attempt_login_user()
          if error.nil?
            session[:user_id] = user.user_id
            r.redirect('/')
          else
            @error = error
            view('login')
          end

        end
      end

      r.on 'register' do
        register_controller = RegisterController.new(r)
        @options = { 'page_title' => 'Register' }

        r.get do
          request.redirect('/') unless user.nil?
          view('register')
        end

        r.post do
          error, user = register_controller.register_user()
          if error.nil? && user.nil?
            r.redirect('/')
          elsif user.nil?
            @error = error
            view('register')
          else
            session[:user_id] = user.user_id
            r.redirect('/')
          end
        end
      end

      r.get 'logout' do
        session.clear
        r.redirect('/')
      end


      r.on 'user' do 
          r.on :target_user_id do |target_user_id|

            user_controller = UserController.new(user, target_user_id)
            if user_controller.target_user.nil?
              r.redirect('/')
            end

            r.on 'follow' do 
              if user_controller.attempt_follow
                r.redirect("/user/#{user_controller.target_user.user_id}")
              else
                r.redirect('/')
              end
            end

            r.on 'unfollow' do 
              if user_controller.attempt_unfollow
                r.redirect("/user/#{user_controller.target_user.user_id}")
              else
                r.redirect('/')
              end
            end

            @options = {
              'page_title' => "#{user_controller.target_user.username}'s timeline",
              'request_endpoint' => 'user_timeline'
            }

            @user = user
            @target_user = user_controller.target_user
            @is_follower = user_controller.check_if_following_target_user
            @messages = user_controller.messages_from_target_user
            view('timeline')

          end
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
# rubocop:enable BlockLength, ClassLength
