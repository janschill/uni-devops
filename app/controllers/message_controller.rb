# frozen_string_literal: true

require './controllers/application_controller'

# Add a message to the database
class MessageController < ApplicationController
  attr_accessor :logged_in_user

  def initialize(request, user)
    super(request)
    @logged_in_user = user
  end

  def add_message
    text = request.params['text']
    message = nil
    if text != ''
      message = Message.new(
        text: text,
        user_id: @logged_in_user.user_id,
        pub_date: Time.now.to_i,
        flagged: false
      )
      message.save_changes
    end
    message
  end
end
