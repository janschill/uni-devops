# frozen_string_literal: true

require 'dotenv'
Dotenv.load

require './config/app_environment'
require './minitwit'
# require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'
# use Prometheus::Middleware::Collector # left for debugging purposes
use Prometheus::Middleware::Exporter

run MiniTwit::App.freeze.app
