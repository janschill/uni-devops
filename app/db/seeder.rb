# frozen_string_literal: true

require 'bcrypt'
require 'faker'
require 'sequel'
require 'literate_randomizer'
require 'yaml'

database = YAML.load_file('config/database.yml')
DB = Sequel.connect(
  "#{database['default']['adapter']}://"\
  "#{database['development']['database']}"
)
DB[:users].truncate
DB[:messages].truncate
DB[:followers].truncate
users = DB[:users]
messages = DB[:messages]
followers = DB[:followers]

10.times do
  users.insert(
    email: Faker::Internet.email,
    username: "#{Faker::Name.first_name}_#{Time.now.to_i}",
    password: BCrypt::Password.create('secret')
  )
end

10.times do
  followers.insert(
    who_id: users.all.sample[:user_id],
    whom_id: users.all.sample[:user_id]
  )
end

100.times do
  messages.insert(
    user_id: users.all.sample[:user_id],
    text: LiterateRandomizer.sentence,
    pub_date: Time.now.to_i,
    flagged: 0
  )
end
