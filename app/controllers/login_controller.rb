# frozen_string_literal: true

require './controllers/application_controller'

# Handle authentication: login/register
class LoginController < ApplicationController
  attr_accessor :logged_in_user

  def initialize(logged_in_user)
    @logged_in_user = logged_in_user
  end

  def login_user(request)
    User.where(username: request.params['username']).first
  end
end
