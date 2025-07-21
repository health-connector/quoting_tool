# frozen_string_literal: true

module Parsers
  module Products
    # The BenefitsListParser is responsible for parsing XML data for a list of benefits.
    # It uses HappyMapper to map XML elements to Ruby objects for benefits information.
    class BenefitsListParser
      include HappyMapper

      tag 'benefitsList'

      has_many :benefits, Parsers::Products::BenefitsParser, tag: 'benefits', dependent: :destroy

      # Converts the parsed benefits list to a hash representation
      # @return [Hash] Benefits list data in hash format
      def to_hash
        {
          benefits: benefits.map(&:to_hash)
        }
      end
    end
  end
end
