# frozen_string_literal: true

module Parsers
  module Products
    # PlanListParser is responsible for parsing collections of insurance plans
    # from XML data. It acts as a container for multiple PlanParser instances.
    class PlanListParser
      include HappyMapper

      tag 'plansList'

      has_many :plans, Parsers::Products::PlanParser, tag: 'plans', dependent: :destroy

      # Converts the collection of parsed plans to a standardized hash format
      # @return [Hash] Collection of structured plan data
      def to_hash
        {
          plans: plans.map(&:to_hash)
        }
      end
    end
  end
end
