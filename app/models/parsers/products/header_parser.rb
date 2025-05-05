# frozen_string_literal: true

module Parsers
  module Products
    # Parses the header section from plan benefit templates
    # Contains general information about the template, issuer, and market
    class HeaderParser
      include HappyMapper

      tag 'header'

      # Version information
      element :template_version, String, tag: 'templateVersion'

      # Issuer identification
      element :issuer_id, String, tag: 'issuerId'
      element :tin, String, tag: 'tin'

      # State and market information
      element :state_postal_code, String, tag: 'statePostalCode'
      element :state_postal_name, String, tag: 'statePostalName'
      element :market_coverage, String, tag: 'marketCoverage'

      # Plan type indicators
      element :dental_plan_only_ind, String, tag: 'dentalPlanOnlyInd'

      # Application information
      element :application_id, String, tag: 'applicationId'

      # Converts the parsed header data into a structured hash format
      # @return [Hash] Clean, normalized header attributes
      def to_hash
        {
          template_version: template_version.gsub("\n", '').strip,
          issuer_id: issuer_id.gsub("\n", '').strip,
          state_postal_code: state_postal_code.gsub("\n", '').strip,
          state_postal_name: state_postal_name.present? ? state_postal_name.gsub("\n", '').strip : '',
          market_coverage: market_coverage.gsub("\n", '').strip,
          dental_plan_only_ind: dental_plan_only_ind.gsub("\n", '').strip,
          tin: tin.present? ? tin.gsub("\n", '').gsub('-', '').strip : '',
          application_id: application_id.present? ? application_id.gsub("\n", '').strip : ''
        }
      end
    end
  end
end
