# frozen_string_literal: true

module Parsers
  module Products
    # PlanRateGroupParser is responsible for parsing individual rate groups for insurance plans.
    # Each rate group contains header information and multiple rate items that define pricing.
    class PlanRateGroupParser
      include HappyMapper

      tag 'qhpApplicationRateGroupVO'

      has_one :header, Parsers::Products::PlanRateHeaderParser, tag: 'header', dependent: :destroy
      has_many :items, Parsers::Products::PlanRateItemsParser, tag: 'items', dependent: :destroy

      # Converts the parsed plan rate group to a standardized hash format
      # @return [Hash] Structured rate group data including header and rate items
      def to_hash
        {
          header: header.to_hash,
          items: items.map(&:to_hash)
        }
      end
    end
  end
end
