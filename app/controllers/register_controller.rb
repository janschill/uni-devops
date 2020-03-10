# frozen_string_literal: true

require './controllers/application_controller'
require 'bcrypt'

# Write user to database
class RegisterController < ApplicationController

  def initialize(request)
    super(request)
  end

  def register_user()
    user = nil
    error = nil
    username = @request.params['username']
    email_address = @request.params['email_address']
    password = @request.params['password']
    password2 = @request.params['password2']
    if username.nil?
      error = 'You have to enter a username'
    elsif email_address.nil?
      error = 'You have to enter a valid email address'
    elsif password.nil?
      error = 'You have to enter a password'
    elsif password != password2
      error = 'Password do not match'
    end 
    other_user = User.where(username: username).first

    if !other_user.nil?
      error = 'Username has already been taken'
    else
      user = User.new(
        email: email_address,
        username: username,
        password: BCrypt::Password.create(password)
      ).save_changes
      user.save_changes
    end
    return error, user
  end
end
