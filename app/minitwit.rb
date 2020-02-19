# frozen_string_literal: true

require 'roda'
require './models'
require './controllers/user_controller'
require './controllers/login_controller'
require './controllers/register_controller'
require './controllers/message_controller'

# rubocop:disable BlockLength
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

      r.root do
        r.redirect('public') if user.nil?
        @options = {
          'page_title' => 'My timeline',
          'request_endpoint' => 'timeline'
        }
        @messages = Message.messages_by_user_id_and_followers(user.user_id)
        @user = user
        view('timeline')
      end

      r.get 'public' do
        @options = {
          'page_title' => 'Public timeline'
        }
        @user = user
        @messages = Message.latest_messages
        view('timeline')
      end

      # TODO: use 403 for redirect
      r.post 'add_message' do
        r.redirect('/') if session['user_id'].nil?
        message_controller = MessageController.new(user)
        message_controller.add_message(request)
        r.redirect('/')
      end

      r.on 'login' do
        login_controller = LoginController.new(user)
        @options = { 'page_title' => 'Login' }

        r.get do
          @error = nil
          request.redirect('/') unless user.nil?
          view('login')
        end

        r.post do
          @error = nil
          user = login_controller.login_user(request)

          if user.nil?
            @error = 'Invalid username'
          elsif !user.password == r.params['password']
            @error = 'Invalid password'
          else
            session[:user_id] = user.user_id
            r.redirect('/')
          end
          view('login')
        end
      end

      r.on 'register' do
        register_controller = RegisterController.new(user)
        @options = { 'page_title' => 'Login' }

        r.get do
          @error = nil
          request.redirect('/') unless user.nil?
          view('register')
        end

        r.post do
          @error = register_controller.register_user(request)
          view('register')
        end
      end

      r.get 'logout' do
        session.clear
        r.redirect('/')
      end

      r.on :username do |username|
        user_controller = UserController.new(username, user)
        r.redirect('/') if user_controller.profile_user.nil?

        r.on 'follow' do
          user_controller.follow(r)
        end

        r.on 'unfollow' do
          user_controller.unfollow(r)
        end

        @options = {
          'page_title' => "#{username}'s timeline",
          'request_endpoint' => 'user_timeline'
        }
        @user = user
        @profile_user = user_controller.profile_user
        @is_follower = user_controller.check_if_follower
        @messages = user_controller.messages_from_profile_user

        view('timeline')
      end
    end
  end
end

# rubocop:enable BlockLength
