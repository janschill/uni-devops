# frozen_string_literal: true

require './controllers/application_controller'
require 'bcrypt'

# Handle authentication: login/register
class LoginController < ApplicationController
  def initialize(request)
    super(request)
  end

  def attempt_login_user
    user = User.where(username: @request.params['username']).first
    error = nil
    if user.nil?
      error = 'Invalid username'
    elsif BCrypt::Password.new(user.password) != @request.params['password']
      error = 'Invalid password'
    end
    [error, user]
  end
end
