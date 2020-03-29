# frozen_string_literal: true

module Stalker
  class Formatter
    def self.replace_dots(string)
      string.gsub '.', '-'
    end

    def self.seconds_to_milli(seconds)
      (seconds * 1000).to_i
    end
  end
end
