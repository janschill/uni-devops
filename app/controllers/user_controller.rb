# frozen_string_literal: true

require './controllers/application_controller'

# All necessary actions to handle /<username>
class UserController < ApplicationController
  attr_reader :username, :logged_in_user
  attr_accessor :profile_user

  def initialize(username, logged_in_user)
    @username = username
    @logged_in_user = logged_in_user

    @profile_user = User.where(username: username).first
  end

  def follow(request)
    request.redirect('/') if @logged_in_user.nil?
    request.redirect('/') if @profile_user.nil?
    Follower.new(
      whom_id: @profile_user.user_id,
      who_id: @logged_in_user.user_id
    ).save_changes
    request.redirect("/#{@profile_user.username}")
  end

  def unfollow(request)
    request.redirect('/') if @logged_in_user.nil?
    request.redirect('/') if @profile_user.nil?
    Follower.where(
      whom_id: @profile_user.user_id,
      who_id: @logged_in_user.user_id
    ).delete
    request.redirect("/#{@profile_user.username}")
  end

  def check_if_follower
    is_follower = false
    unless @logged_in_user.nil?
      follower = Follower.where(
        who_id: @logged_in_user.user_id, whom_id: @profile_user.user_id
      ).first
      is_follower = true unless follower.nil?
    end
    is_follower
  end

  def messages_from_profile_user
    Message.messages_by_user_id(@profile_user.user_id)
  end
end
