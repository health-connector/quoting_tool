# frozen_string_literal: true

module Parsers
  module Products
    # Parses individual packages from plan benefit templates
    # A package contains the header, plans list, and benefits list
    class PackageParser
      include HappyMapper

      tag 'packages'

      # Plan information
      has_one :plans_list, Parsers::Products::PlanListParser, tag: 'plansList', dependent: :destroy

      # Benefits information
      has_one :benefits_list, Parsers::Products::BenefitsListParser, tag: 'benefitsList', dependent: :destroy

      # Header information
      has_one :header, Parsers::Products::HeaderParser, tag: 'header', dependent: :destroy

      # Converts the parsed package data into a structured hash format
      # @return [Hash] Hash containing header, plans list, and benefits list
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
