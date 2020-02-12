# frozen_string_literal: true

require './controllers/application_controller'
require 'bcrypt'

# Write user to database
class RegisterController < ApplicationController
  attr_accessor :logged_in_user

  def initialize(logged_in_user)
    @logged_in_user = logged_in_user
  end

  def register_user(request)
    error = nil
    username = request.params['username']
    email_address = request.params['email_address']
    password = request.params['password']
    password2 = request.params['password2']
    if username.nil?
      error = 'You have to enter a username'
    elsif email_address.nil?
      error = 'You have to enter a valid email address'
    elsif password.nil?
      error = 'You have to enter a password'
    elsif password != password2
      error = 'Password do not match'
    else
      User.new(
        email: email_address,
        username: username,
        password: BCrypt::Password.create(password)
      ).save_changes
      request.redirect('login')
    end
    error
  end
end
