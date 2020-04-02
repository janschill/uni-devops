# frozen_string_literal: true

require 'fileutils'
require 'stalker/formatter'

module Stalker
  class Writer
    attr_accessor :filename

    def initialize(site)
      today = Time.now.strftime('%Y%m%d')
      filename = "#{Formatter.replace_dots(site['address'])}-#{today}-ping"
      extension = 'log'
      FileUtils.mkdir_p 'log' unless File.exist?('log')
      @filename = "log/#{filename}.#{extension}"
      File.new(@filename, 'w') unless File.exist?(@filename)
    end

    def write(message)
      File.write(@filename, "#{message}\n", mode: 'a')
    end

    def write_connection(connector, site)
      now = Time.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z') # ISO 8061
      content = "[#{now}] \"GET #{site['path']}\" #{connector.status} #{Formatter.seconds_to_milli(connector.response_time)}"
      write(content)
    end
  end
end
