# frozen_string_literal: true

require 'dotenv'
Dotenv.load

require './config/app_environment'
require './minitwit'

run MiniTwit::App.freeze.app
