# frozen_string_literal: true

require 'dotenv'
Dotenv.load

require './minitwit'

run MiniTwit::App.freeze.app
