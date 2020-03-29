# frozen_string_literal: true

require './minitwit_sim_api'

require 'yaml'
log_config = YAML.load_file('config/log.yml')

require 'logger'
logger = Logger.new(log_config['access']['filepath'])
use Rack::CommonLogger, logger

# require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'
use Prometheus::Middleware::Exporter
# require 'prometheus/middleware/collector'
# use Prometheus::Middleware::Collector # left for debugging purposes

Prometheus::Client.registry.gauge(:minitwit_api_starttime_seconds, docstring: 'A gauge of startup time').set(Time.now.to_i)

run MiniTwit::SimAPI.freeze.app
