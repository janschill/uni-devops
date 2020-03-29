# frozen_string_literal: true

require 'stalker/version'
require 'stalker/connector'
require 'stalker/writer'
require 'yaml'

module Stalker
  class Stalker
    def self.stalk
      sites = YAML.load_file('config/sites.yml')
      sites['uris'].each do |site|
        connector = Connector.new(site['address'], site['protocol'], site['port'], site['path'])
        connector.request
        writer = Writer.new(site)
        writer.write(connector, site)
      end
    end
  end
end
