#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dotenv'

Dotenv.load

if ARGV[0] == 'init'
  if File.exist?("/tmp/#{ENV['DATABASE_NAME']}.db")
    puts 'Database already exists.'
    exit 1
  end
  puts "Putting a database to /tmp/#{ENV['DATABASE_NAME']}.db..."
  # TODO: Create database from web service
  system("sqlite3 /tmp/#{ENV['DATABASE_NAME']}.db < ./db/schema.sql")
elsif ARGV[0] == 'start'
  puts 'Starting minitwit...'
  system('nohup rackup > /tmp/out.log 2>&1 &')
  sleep(0.5)
  minitwit_port = `cat /tmp/out.log | grep pid= | cut -d ' ' -f 7 | cut -d '=' -f 2`
  minitwit_pid = `cat /tmp/out.log | grep pid= | cut -d ' ' -f 6 | cut -d '=' -f 2`
  puts "Starting server on PID: #{minitwit_pid} and port: #{minitwit_port}"
elsif ARGV[0] == 'stop'
  minitwit_pid = `cat /tmp/out.log | grep pid= | cut -d ' ' -f 6 | cut -d '=' -f 2`
  puts "Stopping minitwit on PID: #{minitwit_pid}"
  system("kill -TERM #{minitwit_pid}")
elsif ARGV[0] == 'inspectdb'
  puts `./bin/flag_tool.rb -i | less`
elsif ARGV[0] == 'flag'
  ARGV.each { |flag| system("./bin/flag_tool #{flag}") }
else
  puts 'I do not know this command...'
end
