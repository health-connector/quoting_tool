# frozen_string_literal: true

module Parsers
  module Products
    # The BenefitsParser is responsible for parsing XML data for individual benefit information.
    # It uses HappyMapper to map XML elements to Ruby objects for benefit details such as
    # coverage information, limitations, and exclusions.
    class BenefitsParser
      include HappyMapper
      include ValueRetrievalHelper

      tag 'benefits'

      element :benefit_type_code, String, tag: 'benefitTypeCode'
      element :is_ehb, String, tag: 'isEHB'
      element :is_state_mandate, String, tag: 'isStateMandate'
      element :is_benefit_covered, String, tag: 'isBenefitCovered'
      element :service_limit, String, tag: 'serviceLimit'
      element :quantity_limit, String, tag: 'quantityLimit'
      element :unit_limit, String, tag: 'unitLimit'
      element :minimum_stay, String, tag: 'minimumStay'
      element :exclusion, String, tag: 'exclusion'
      element :explanation, String, tag: 'explanation'
      element :ehb_variance_reason, String, tag: 'ehbVarianceReason'
      element :subject_to_deductible_tier_1, String, tag: 'subjectToDeductibleTier1'
      element :subject_to_deductible_tier_2, String, tag: 'subjectToDeductibleTier2'
      element :excluded_in_network_moop, String, tag: 'excludedInNetworkMOOP'
      element :excluded_out_of_network_moop, String, tag: 'excludedOutOfNetworkMOOP'

      # Converts the parsed benefit to a hash representation with cleaned values
      # @return [Hash] Benefit data in hash format with whitespace and newlines removed

      def to_hash
        self.class.elements.to_h do |el|
          [el.name.to_sym, safely_retrive_value(send(el.name))]
        end
      end
    end
  end
end
