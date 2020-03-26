# frozen_string_literal: true

require './minitwit_sim_api'

require 'yaml'
log_config = YAML.load_file('config/log.yml')

require 'logger'
logger = Logger.new(log_config['access']['filepath'])
use Rack::CommonLogger, logger

require 'prometheus/middleware/exporter'
use Prometheus::Middleware::Exporter
# require 'prometheus/middleware/collector'
# use Prometheus::Middleware::Collector # left for debugging purposes

run MiniTwit::SimAPI.freeze.app
