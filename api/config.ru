# frozen_string_literal: true

require 'dotenv'
Dotenv.load

require './minitwit_sim_api'

run MiniTwit::SimAPI.freeze.app