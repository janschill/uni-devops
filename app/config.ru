# frozen_string_literal: true

require 'dotenv'
Dotenv.load

require 'yaml'
log_config = YAML.load_file('config/log.yml')

require 'logger'
logger = Logger.new(log_config['access']['filepath'])
use Rack::CommonLogger, logger

require './config/app_environment'
require './minitwit'
require 'prometheus/middleware/exporter'
use Prometheus::Middleware::Exporter

Prometheus::Client.registry.gauge(:minitwit_app_starttime_seconds, docstring: 'A gauge of startup time').set(Time.now.to_i)

run MiniTwit::App.freeze.app
