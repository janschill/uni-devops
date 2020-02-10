require 'dotenv'
Dotenv.load

require './minitwit'

run MiniTwit::App.freeze.app
