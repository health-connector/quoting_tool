# frozen_string_literal: true

module Parsers
  module Products
    class PackageParser
      include HappyMapper

      tag 'packages'

      has_one :plans_list, Parsers::Products::PlanListParser, tag: 'plansList'

      has_one :benefits_list, Parsers::Products::BenefitsListParser, tag: 'benefitsList'

      has_one :header, Parsers::Products::HeaderParser, tag: 'header'

      def to_hash
        {
          header: header.to_hash,
          plans_list: plans_list.to_hash,
          benefits_list: benefits_list.to_hash
        }
      end
    end
  end
end
