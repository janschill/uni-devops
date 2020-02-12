#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dotenv'
require 'sequel'

Dotenv.load

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
DB = Sequel.sqlite("/tmp/#{ENV['DATABASE_NAME']}.db")
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
