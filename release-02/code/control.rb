#!/usr/bin/env ruby

if ARGV[0] == "init"
    if File.exist?('/tmp/minitwit.db')
        puts "Database already exists."
        exit 1
    end
    puts "Putting a database to /tmp/minitwit.db..."
    system("python -c from minitwit import init_db;init_db()")
elsif ARGV[0] == "start"
    puts "Starting minitwit..."
    system("nohup python minitwit.py3 > /tmp/out.log 2>&1 &")
    system("echo \"$!\" > /tmp/minitwit.pid")
elsif ARGV[0] == "stop"
    puts "Stopping minitwit..."
    minitwit_pid = `cat /tmp/minitwit.pid`
    system("kill -TERM \"$MINITWIT_PID\"")
    system("rm /tmp/minitwit.pid")
elsif ARGV[0] == "inspectdb"
    `./flag_tool -i | less`
elsif ARGV[0] == "flag"
    ARGV.each { |flag| system("./flag_tool #{flag}") }
else
    puts "I do not know this command..."
end