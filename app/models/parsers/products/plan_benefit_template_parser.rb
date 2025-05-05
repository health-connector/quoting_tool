# frozen_string_literal: true

module Parsers
  module Products
    # Root parser for plan benefit templates (PBT)
    # Acts as the entry point for parsing the entire PBT XML structure
    class PlanBenefitTemplateParser
      include HappyMapper

      tag 'planBenefitTemplateVO'

      # The packages list containing all plan packages
      has_one :packages_list, PackageListParser, tag: 'packagesList', dependent: :destroy

      # Converts the parsed plan benefit template data into a structured hash format
      # @return [Hash] Complete hash representation of the plan benefit template
      def to_hash
        {
          packages_list: packages_list.to_hash
        }
      end
    end
  end
end
