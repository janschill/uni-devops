# frozen_string_literal: true

require 'roda'
require './models'
require 'bcrypt'

module MiniTwit
  class App < Roda
    plugin :assets, css: ['style.css']
    plugin :render
    plugin :hooks
    plugin :sessions,
           key: ENV['SESSION_KEY'],
           secret: ENV['SESSION_RAND']

    user = nil

    # Check if user is in session
    before do
      user = nil
      unless session['user_id'].nil?
        user = User.where(user_id: session['user_id']).first
      end
    end

    route do |r|
      r.assets
      # TODO: Fix Message method to also fetch followed messages
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
        if session['user_id'].nil?
          r.redirect('/')
        else
          text = r.params['text']
          if text != ''
            Message.new(
              text: text,
              user_id: user.user_id,
              pub_date: Time.now.to_i,
              flagged: false
            ).save_changes
          end
          r.redirect('/')
        end
      end

      r.on 'login' do
        r.get do
          @error = nil
          r.redirect('/') unless user.nil?
          view('login')
        end

        r.post do
          @error = nil
          user = User.where(username: r.params['username']).first

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
        r.get do
          r.redirect('/') unless user.nil?
          view('register')
        end

        r.post do
          @error = nil
          username = r.params['username']
          email_address = r.params['email_address']
          password = r.params['password']
          password2 = r.params['password2']
          if username.nil?
            @error = 'You have to enter a username'
          elsif email_address.nil?
            @error = 'You have to enter a valid email address'
          elsif password.nil?
            @error = 'You have to enter a password'
          elsif password != password2
            @error = 'Password do not match'
          else
            User.new(
              email: email_address,
              username: username,
              password: BCrypt::Password.create(password)
            ).save_changes
            r.redirect('login')
          end
          view('register')
        end
      end

      r.get 'logout' do
        session.clear
        r.redirect('/')
      end

      r.on :username do |username|
        @profile_user = User.where(username: username).first
        whom_id = @profile_user.user_id
        @user = user

        r.on 'follow' do
          r.redirect('/') if user.nil?
          r.redirect('/') if whom_id.nil?
          Follower.new(
            whom_id: whom_id,
            who_id: @user.user_id
          ).save_changes
          r.redirect("/#{@profile_user.username}")
        end

        r.on 'unfollow' do
          r.redirect('/') if user.nil?
          r.redirect('/') if whom_id.nil?
          Follower.where(
            whom_id: whom_id,
            who_id: @user.user_id
          ).delete
          r.redirect("/#{@profile_user.username}")
        end

        @options = {
          'page_title' => "#{username}'s timeline",
          'request_endpoint' => 'user_timeline'
        }
        r.redirect('/') if @profile_user.nil?

        @followed = false
        unless @user.nil?
          follower = Follower.where(who_id: @user.user_id, whom_id: whom_id).first
          @followed = true unless follower.nil?
        end
        @messages = Message.messages_by_user_id(@profile_user.user_id)

        view('timeline')
      end
    end
  end
end
