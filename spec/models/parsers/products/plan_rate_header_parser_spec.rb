# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Parsers::Products::PlanRateHeaderParser do
  describe 'parsing' do
    let(:xml_data) do
      <<~XML
        <header>
          <applicationId>APP123456\n</applicationId>
          <lastModifiedDate>2023-04-15\n</lastModifiedDate>
          <lastModifiedBy>John Doe</lastModifiedBy>
          <documents>Doc1, Doc2</documents>
          <statements>No comments\n</statements>
          <status>Approved\n</status>
          <attestationIndicator>Y\n</attestationIndicator>
          <tin>12-3456789\n</tin>
          <issuerId>98765\n</issuerId>
          <submissionType>New\n</submissionType>
          <marketType>Individual\n</marketType>
          <marketDivisionType>Standard\n</marketDivisionType>
          <marketCoverageType>Health\n</marketCoverageType>
          <templateVersion>1.2\n</templateVersion>
        </header>
      XML
    end

    let(:empty_header_xml) do
      <<~XML
        <header>
          <applicationId></applicationId>
          <lastModifiedDate></lastModifiedDate>
          <lastModifiedBy></lastModifiedBy>
          <statements></statements>
          <status></status>
          <attestationIndicator></attestationIndicator>
          <tin></tin>
          <issuerId></issuerId>
          <submissionType></submissionType>
          <marketType></marketType>
          <marketDivisionType></marketDivisionType>
          <marketCoverageType></marketCoverageType>
          <templateVersion></templateVersion>
        </header>
      XML
    end

    it 'correctly parses XML into object' do
      parser = described_class.parse(xml_data)

      expect(parser.application_id).to eq("APP123456\n")
      expect(parser.last_modified_date).to eq("2023-04-15\n")
      expect(parser.last_modified_by).to eq("John Doe")
      expect(parser.tin).to eq("12-3456789\n")
      expect(parser.issuer_id).to eq("98765\n")
      expect(parser.market_type).to eq("Individual\n")
    end

    it 'cleans and formats fields in to_hash' do
      parser = described_class.parse(xml_data)
      result = parser.to_hash

      expect(result[:application_id]).to eq("APP123456")
      expect(result[:last_modified_date]).to eq("2023-04-15")
      expect(result[:last_modified_by]).to eq("John Doe")
      expect(result[:statements]).to eq("No comments")
      expect(result[:status]).to eq("Approved")
      expect(result[:tin]).to eq("12-3456789")
      expect(result[:issuer_id]).to eq("98765")
      expect(result[:market_type]).to eq("Individual")
      expect(result[:template_version]).to eq("1.2")
    end

    it 'handles empty fields properly' do
      parser = described_class.parse(empty_header_xml)
      result = parser.to_hash

      expect(result[:application_id]).to eq("")
      expect(result[:last_modified_date]).to eq("")
      expect(result[:market_type]).to eq("")
      expect(result[:template_version]).to eq("")
    end

    it 'includes all expected hash keys' do
      expected_keys = [
        :application_id, :last_modified_date, :last_modified_by, :statements,
        :status, :attestation_indicator, :tin, :issuer_id, :submission_type,
        :market_type, :market_division_type, :market_coverage_type, :template_version
      ]

      result = described_class.parse(xml_data).to_hash
      expect(result.keys).to match_array(expected_keys)
    end
  end
end
