# frozen_string_literal: true

require './minitwit_sim_api'

#require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'
#use Prometheus::Middleware::Collector #collects wayyyy too much stuff
use Prometheus::Middleware::Exporter

run MiniTwit::SimAPI.freeze.app
