# Database and ORM layers

require 'sequel'

module MiniTwit
  DB = Sequel.connect("sqlite://db/#{ENV['DATABASE_NAME']}.db")

  Model = Class.new(Sequel::Model)
  Model.db = DB

  %w'user message follower'.each{|x| require_relative "models/#{x}"}
  # Model.freeze_descendents
  DB.freeze
end
