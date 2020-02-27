# frozen_string_literal: true

require 'sequel'

# Database and ORM layers
module MiniTwit
  DB = Sequel.connect('sqlite:///tmp/minitwit.db')

  Model = Class.new(Sequel::Model)
  Model.db = DB

  %w[user message follower].each { |x| require_relative "models/#{x}" }
  # Model.freeze_descendents
  DB.freeze
end
