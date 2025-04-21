# frozen_string_literal: true

module Parsers
  module Products
    class PlanListParser
      include HappyMapper

      tag 'plansList'

      has_many :plans, Parsers::Products::PlanParser, tag: 'plans'

      def to_hash
        {
          plans: plans.map(&:to_hash)
        }
      end
    end
  end
end
