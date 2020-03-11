# frozen_string_literal: true

require './models'

class ApplicationController
  attr_accessor :request

  def initialize(request)
    @request = request
  end
end
