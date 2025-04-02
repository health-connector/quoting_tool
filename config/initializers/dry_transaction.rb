# Load the compatibility layer for Dry::Transaction::Operation
require 'dry/transaction/operation'

# Add dry-transaction compatibility initializer
Rails.application.config.to_prepare do
  # Ensure dry-transaction and dry-monads are loaded
  require 'dry/transaction'
  require 'dry/monads'
end
