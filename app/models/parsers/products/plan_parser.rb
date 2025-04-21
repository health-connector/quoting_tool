module Parsers
  module Products
    class PlanParser
      include HappyMapper

      tag 'plans'

      has_one :plan_attributes, Parsers::Products::PlanAttributesParser, tag: 'planAttributes'
      has_many :cost_share_variance_list_attributes, Parsers::Products::CostShareVarianceParser,
               tag: 'costShareVariance', deep: true

      def to_hash
        {
          plan_attributes: plan_attributes.to_hash,
          cost_share_variance_list_attributes: cost_share_variance_list_attributes.map(&:to_hash)
        }
      end
    end
  end
end
