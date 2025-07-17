# frozen_string_literal: true

module Parsers
  module Products
    # Parses the Health Savings Account (HSA) information from plan benefit templates
    # Contains details about HSA eligibility and employer contributions
    class HsaParser
      include HappyMapper

      tag 'hsa'

      # HSA eligibility indicator
      element :hsa_eligibility, String, tag: 'hsaEligibility'

      # Employer contribution indicators and amounts
      element :employer_hsahra_contribution_indicator, String, tag: 'employerHSAHRAContributionIndicator'
      element :emp_contribution_amount_for_hsa_or_hra, String, tag: 'empContributionAmountForHSAOrHRA'

      # Converts the parsed HSA data into a structured hash format
      # @return [Hash] Clean, normalized HSA attributes
      def to_hash
        {
          hsa_eligibility: hsa_eligibility.gsub("\n", '').strip,
          employer_hsahra_contribution_indicator: employer_hsahra_contribution_indicator.gsub("\n", '').strip,
          emp_contribution_amount_for_hsa_or_hra: emp_contribution_amount_for_hsa_or_hra.gsub("\n", '').strip
        }
      end
    end
  end
end
