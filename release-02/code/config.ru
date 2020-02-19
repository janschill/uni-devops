# frozen_string_literal: true

require 'dotenv'
Dotenv.load

require './minitwit'
require './minitwit_sim_api'

#run MiniTwit::App.freeze.app
run MiniTwit::SimAPI.freeze.app
