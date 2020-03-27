# frozen_string_literal: true

require './controllers/application_controller'

# All necessary actions to handle /<username>
class UserController < ApplicationController
  attr_reader :logged_in_user
  attr_accessor :target_user

  def initialize(user, target_user_id)
    super(nil)
    @logged_in_user = user
    @target_user = User.where(user_id: target_user_id).first
  end

  def attempt_follow
    return false if @logged_in_user.nil? || @target_user.nil?

    Follower.new(
      whom_id: @target_user.user_id,
      who_id: @logged_in_user.user_id
    ).save_changes
    true
  end

  def attempt_unfollow
    return false if @logged_in_user.nil? || @target_user.nil?

    Follower.where(
      whom_id: @target_user.user_id,
      who_id: @logged_in_user.user_id
    ).delete
    true
  end

  def check_if_following_target_user
    is_follower = false
    unless @logged_in_user.nil?
      follower = Follower.where(
        who_id: @logged_in_user.user_id, whom_id: @target_user.user_id
      ).first
      is_follower = true unless follower.nil?
    end
    is_follower
  end

  def messages_from_target_user(offset)
    Message.messages_by_user_id(@target_user.user_id, offset)
  end
end
