# frozen_string_literal: true

require 'sequel'
require 'yaml'

# Database and ORM layers
module MiniTwit
  databases = YAML.load_file('config/database.yml')

  DB = Sequel.mysql2(
    'minitwit_test',
    user: 'doadmin',
    password: databases['default']['password'].to_s,
    host: 'minitwit-db-do-user-3981230-0.a.db.ondigitalocean.com',
    port: 25060,
    max_connections: 10,
    sslmode: 'require'
  )

  Model = Class.new(Sequel::Model)
  Model.db = DB

  %w[user message follower].each { |x| require_relative "models/#{x}" }
  # Model.freeze_descendents
  DB.freeze
end
