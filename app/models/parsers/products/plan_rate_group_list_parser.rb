# frozen_string_literal: true

module Parsers
  module Products
    # PlanRateGroupListParser is responsible for parsing collections of plan rate groups
    # from XML data. These rate groups contain pricing information for insurance plans.
    class PlanRateGroupListParser
      include HappyMapper

      tag 'qhpApplicationRateGroupListVO'

      has_many :plan_rate_group_attributes, Parsers::Products::PlanRateGroupParser, tag: 'qhpApplicationRateGroupVO', dependent: :destroy

      # Converts the collection of parsed plan rate groups to a standardized hash format
      # @return [Hash] Collection of structured plan rate group data
      def to_hash
        {
          plan_rate_group_attributes: plan_rate_group_attributes.map(&:to_hash)
        }
      end
    end
  end
end
