#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sequel'
require 'yaml'

# Helper script to inspect database
help_text = "ITU-Minitwit Tweet Flagging Tool\n\n" \
            "Usage:\n" \
            "  flag_tool <tweet_id>...\n" \
            "  flag_tool -i\n" \
            "  flag_tool -h\n" \
            "Options:\n" \
            "-h            Show this screen.\n" \
            "-i            Dump all tweets and authors to STDOUT.\n"

def print_tweet(tweet_id, user_id, tweet_text, flagged)
  printf "%s,%s,%s,%s\n",
         tweet_id,
         user_id,
         tweet_text,
         flagged.nil? ? 0 : flagged
end

if ARGV.length == 1 && ARGV[0].eql?('-h')
  puts help_text
  exit(true)
end

databases = YAML.load_file('../config/database.yml')
DB = Sequel.mysql2(
  'minitwit_test',
  user: 'doadmin',
  password: databases['default']['password'].to_s,
  host: 'minitwit-db-do-user-3981230-0.a.db.ondigitalocean.com',
  port: 25060,
  max_connections: 10,
  sslmode: 'require'
)

messages = DB[:messages]

if ARGV.length == 1 && ARGV[0].eql?('-i')
  messages.all.each do |message|
    print_tweet(
      message[:message_id],
      message[:user_id],
      message[:text],
      message[:flagged]
    )
  end
  exit(true)
end

if ARGV.length >= 1 && !(ARGV[0].eql? '-i') && !(ARGV[0].eql? '-h')
  ARGV.each do |id|
    messages.where(message_id: id).update(flagged: 1)
  end
  exit(true)
end
