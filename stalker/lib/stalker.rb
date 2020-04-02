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
        writer = Writer.new(site)
        begin
          connector = Connector.new(site['address'], site['protocol'], site['port'], site['path'])
          connector.request
          writer.write_conncetion(connector, site)
        rescue StandardError => e
          writer.write(e)
        end
      end
    end
  end
end
