# frozen_string_literal: true

require 'sequel'
require 'yaml'

# Database and ORM layers
module MiniTwit
  databases = YAML.load_file('config/database.yml')
  DB = Sequel.connect(
    "#{databases['default']['adapter']}://"\
    "#{databases[AppEnvironment.environment.to_s]['database']}"
  )

  Model = Class.new(Sequel::Model)
  Model.db = DB

  %w[user message follower].each { |x| require_relative "models/#{x}" }
  # Model.freeze_descendents
  DB.freeze
end
