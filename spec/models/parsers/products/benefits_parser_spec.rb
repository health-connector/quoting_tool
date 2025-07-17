# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Parsers::Products::BenefitsParser do
  let(:xml_data) do
    <<-XML
      <benefits>
        <benefitTypeCode>Primary Care Visit to Treat an Injury or Illness</benefitTypeCode>
        <isEHB>Yes</isEHB>
        <isStateMandate>No</isStateMandate>
        <isBenefitCovered>Covered</isBenefitCovered>
        <serviceLimit>Limited to 5 visits per year</serviceLimit>
        <quantityLimit>5</quantityLimit>
        <unitLimit>Visit</unitLimit>
        <minimumStay>1 Day</minimumStay>
        <exclusion>Does not cover preventive care</exclusion>
        <explanation>Requires referral from PCP</explanation>
        <ehbVarianceReason>Standard benefit</ehbVarianceReason>
        <subjectToDeductibleTier1>Yes</subjectToDeductibleTier1>
        <subjectToDeductibleTier2>No</subjectToDeductibleTier2>
        <excludedInNetworkMOOP>No</excludedInNetworkMOOP>
        <excludedOutOfNetworkMOOP>Yes</excludedOutOfNetworkMOOP>
      </benefits>
    XML
  end

  let(:xml_with_whitespace) do
    <<-XML
      <benefits>
        <benefitTypeCode>
          Primary Care Visit
        </benefitTypeCode>
        <isEHB>Yes </isEHB>
        <isStateMandate> No </isStateMandate>
        <isBenefitCovered>Covered</isBenefitCovered>
        <serviceLimit>Limited to 5 visits</serviceLimit>
        <quantityLimit>5</quantityLimit>
        <unitLimit>Visit</unitLimit>
        <minimumStay>1 Day</minimumStay>
        <exclusion>None</exclusion>
        <explanation>Requires referral</explanation>
        <ehbVarianceReason>Standard</ehbVarianceReason>
        <subjectToDeductibleTier1>Yes</subjectToDeductibleTier1>
        <subjectToDeductibleTier2>No</subjectToDeductibleTier2>
        <excludedInNetworkMOOP>No</excludedInNetworkMOOP>
        <excludedOutOfNetworkMOOP>Yes</excludedOutOfNetworkMOOP>
      </benefits>
    XML
  end

  let(:xml_with_missing_fields) do
    <<-XML
      <benefits>
        <benefitTypeCode>Primary Care Visit</benefitTypeCode>
        <isEHB>Yes</isEHB>
        <isBenefitCovered>Covered</isBenefitCovered>
        <serviceLimit>Limited</serviceLimit>
        <quantityLimit>5</quantityLimit>
        <unitLimit>Visit</unitLimit>
        <exclusion>None</exclusion>
        <explanation>Required</explanation>
        <ehbVarianceReason>Standard</ehbVarianceReason>
        <excludedInNetworkMOOP>No</excludedInNetworkMOOP>
        <excludedOutOfNetworkMOOP>Yes</excludedOutOfNetworkMOOP>
      </benefits>
    XML
  end

  describe "parsing XML" do
    it "correctly parses XML elements" do
      benefits = described_class.parse(xml_data)

      expect(benefits).to be_a(described_class)
      expect(benefits.benefit_type_code).to eq("Primary Care Visit to Treat an Injury or Illness")
      expect(benefits.is_ehb).to eq("Yes")
      expect(benefits.is_state_mandate).to eq("No")
      expect(benefits.is_benefit_covered).to eq("Covered")
      expect(benefits.service_limit).to eq("Limited to 5 visits per year")
      expect(benefits.quantity_limit).to eq("5")
      expect(benefits.unit_limit).to eq("Visit")
      expect(benefits.minimum_stay).to eq("1 Day")
      expect(benefits.exclusion).to eq("Does not cover preventive care")
      expect(benefits.explanation).to eq("Requires referral from PCP")
      expect(benefits.ehb_variance_reason).to eq("Standard benefit")
      expect(benefits.subject_to_deductible_tier_1).to eq("Yes")
      expect(benefits.subject_to_deductible_tier_2).to eq("No")
      expect(benefits.excluded_in_network_moop).to eq("No")
      expect(benefits.excluded_out_of_network_moop).to eq("Yes")
    end
  end

  describe "#to_hash" do
    it "converts parsed data to a hash with cleaned values" do
      benefits = described_class.parse(xml_with_whitespace)
      hash = benefits.to_hash

      expect(hash).to be_a(Hash)
      expect(hash[:benefit_type_code]).to eq("Primary Care Visit")
      expect(hash[:is_ehb]).to eq("Yes")
      expect(hash[:is_state_mandate]).to eq("No")
    end

    it "handles missing fields gracefully" do
      benefits = described_class.parse(xml_with_missing_fields)
      hash = benefits.to_hash

      expect(hash[:is_state_mandate]).to eq("")
      expect(hash[:minimum_stay]).to eq("")
      expect(hash[:subject_to_deductible_tier_1]).to eq("")
      expect(hash[:subject_to_deductible_tier_2]).to eq("")
    end
  end
end
