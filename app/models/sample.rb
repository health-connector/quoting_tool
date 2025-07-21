# frozen_string_literal: true

# Sample model for demonstration purposes
# A simple model with a message field
class Sample
  include Mongoid::Document
  include Mongoid::Timestamps
  field :message, type: String
end
