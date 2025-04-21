# frozen_string_literal: true

module Parsers
  module Products
    class BenefitsListParser
      include HappyMapper

      tag 'benefitsList'

      has_many :benefits, Parsers::Products::BenefitsParser, tag: 'benefits'

      def to_hash
        {
          benefits: benefits.map(&:to_hash)
        }
      end
    end
  end
end
