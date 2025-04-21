# frozen_string_literal: true

require 'cgi'
require 'dry-types'

Dry::Types.load_extensions(:maybe)
QuotingToolRegistry = ResourceRegistry::Registry.new

QuotingToolRegistry.configure do |config|
  config.name       = :quoting_tool
  config.created_at = DateTime.now
  config.load_path  = Rails.root.join('system', 'config').to_s
end
