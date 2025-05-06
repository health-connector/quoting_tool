# frozen_string_literal: true

module Parsers
  module Products
    # PlanRateHeaderParser is responsible for parsing header information for plan rates.
    # This includes metadata such as issuer information, submission details, market type,
    # and other administrative data related to the plan rates.
    class PlanRateHeaderParser
      include HappyMapper
      include ValueRetrievalHelper
      tag 'header'

      # Administrative fields
      element :application_id, String, tag: 'applicationId'
      element :last_modified_date, String, tag: 'lastModifiedDate'
      element :last_modified_by, String, tag: 'lastModifiedBy'
      element :documents, String, tag: 'documents'
      element :statements, String, tag: 'statements'
      element :status, String, tag: 'status'
      element :attestation_indicator, String, tag: 'attestationIndicator'

      # Issuer identification
      element :tin, String, tag: 'tin'
      element :issuer_id, String, tag: 'issuerId'

      # Market classification fields
      element :submission_type, String, tag: 'submissionType'
      element :market_type, String, tag: 'marketType'
      element :market_division_type, String, tag: 'marketDivisionType'
      element :market_coverage_type, String, tag: 'marketCoverageType'
      element :template_version, String, tag: 'templateVersion'

      # Converts the parsed header data to a standardized hash format,
      # cleaning and normalizing all text fields
      # @return [Hash] Structured and sanitized header data
      def to_hash
        {
          application_id: safely_retrive_value(application_id),
          last_modified_date: safely_retrive_value(last_modified_date),
          last_modified_by: safely_retrive_value(last_modified_by),
          statements: safely_retrive_value(statements),
          status: safely_retrive_value(status),
          attestation_indicator: safely_retrive_value(attestation_indicator),
          tin: safely_retrive_value(tin),
          issuer_id: safely_retrive_value(issuer_id),
          submission_type: safely_retrive_value(submission_type),
          market_type: safely_retrive_value(market_type),
          market_division_type: safely_retrive_value(market_division_type),
          market_coverage_type: safely_retrive_value(market_coverage_type),
          template_version: safely_retrive_value(template_version)
        }
      end
    end
  end
end
