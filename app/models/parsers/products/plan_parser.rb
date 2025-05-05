# frozen_string_literal: true

module Parsers
  module Products
    # PlanParser is responsible for parsing individual insurance plan data
    # from XML format using HappyMapper. It extracts plan attributes and
    # cost share variance information.
    class PlanParser
      include HappyMapper

      tag 'plans'

      has_one :plan_attributes, Parsers::Products::PlanAttributesParser, tag: 'planAttributes', dependent: :destroy
      has_many :cost_share_variance_list_attributes, Parsers::Products::CostShareVarianceParser,
               tag: 'costShareVariance', deep: true, dependent: :destroy

      # Converts parsed plan data to a standardized hash format
      # @return [Hash] Structured plan data including attributes and cost share variances
      def to_hash
        {
          plan_attributes: plan_attributes.to_hash,
          cost_share_variance_list_attributes: cost_share_variance_list_attributes.map(&:to_hash)
        }
      end
    end
  end
end
