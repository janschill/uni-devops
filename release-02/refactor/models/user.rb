# frozen_string_literal: true

# Model for the users of MiniTwit
class User < Sequel::Model
  one_to_many :messages
end
