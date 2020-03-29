# frozen_string_literal: true

require 'net/http'
require 'benchmark'

module Stalker
  class Connector
    attr_accessor :uri, :response, :response_time

    def initialize(address, protocol, port, path)
      @uri = URI("#{protocol}://#{address}:#{port}#{path}")
    end

    def request
      @response_time = Benchmark.realtime do
        @response = Net::HTTP.get_response(@uri)
      end
      @response
    end

    def status
      @response.code
    end
  end
end
