# frozen_string_literal: true

module Parsers
  module Products
    class PlanRateGroupListParser
      include HappyMapper

      tag 'qhpApplicationRateGroupListVO'

      has_many :plan_rate_group_attributes, Parsers::Products::PlanRateGroupParser, tag: 'qhpApplicationRateGroupVO'

      def to_hash
        {
          plan_rate_group_attributes: plan_rate_group_attributes.map(&:to_hash)
        }
      end
    end
  end
end
