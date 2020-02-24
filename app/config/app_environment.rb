# frozen_string_literal: true

# Making application environment globally available
class AppEnvironment
  def self.development?
    ENV['APP_ENVIRONMENT'].intern == :development
  end

  def self.test?
    ENV['APP_ENVIRONMENT'].intern == :test
  end

  def self.production?
    ENV['APP_ENVIRONMENT'].intern == :production
  end

  def self.environment
    ENV['APP_ENVIRONMENT'].intern
  end
end
