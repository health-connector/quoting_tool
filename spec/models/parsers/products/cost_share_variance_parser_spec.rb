# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Parsers::Products::CostShareVarianceParser do
  let(:subject) { described_class }

  describe '#parse' do
    context 'given valid XML input' do
      let(:xml) do
        <<-XML
          <costShareVariance>
            <planId>12345XX9876001-01</planId>
            <planMarketingName>Sample Plan Name</planMarketingName>
            <planVariantMarketingName>Sample Variant Name</planVariantMarketingName>
            <metalLevel>Gold</metalLevel>
            <csrVariationType>01</csrVariationType>
            <issuerActuarialValue>0.8</issuerActuarialValue>
            <avCalculatorOutputNumber>0.79</avCalculatorOutputNumber>
            <medicalAndDrugDeductiblesIntegrated>Yes</medicalAndDrugDeductiblesIntegrated>
            <medicalAndDrugMaxOutOfPocketIntegrated>Yes</medicalAndDrugMaxOutOfPocketIntegrated>
            <isSpecialistReferralRequired>No</isSpecialistReferralRequired>
            <multipleProviderTiers>Yes</multipleProviderTiers>
            <firstTierUtilization>0.85</firstTierUtilization>
            <secondTierUtilization>0.15</secondTierUtilization>
            <defaultCopayInNetwork>10.00</defaultCopayInNetwork>
            <defaultCopayOutOfNetwork>20.00</defaultCopayOutOfNetwork>
            <defaultCoInsuranceInNetwork>0.2</defaultCoInsuranceInNetwork>
            <defaultCoInsuranceOutOfNetwork>0.4</defaultCoInsuranceOutOfNetwork>
            <planDeductible></planDeductible>
            <moop></moop>
            <hsa></hsa>
            <serviceVisit></serviceVisit>
          </costShareVariance>
        XML
      end

      let(:parsed_data) { subject.parse(xml) }

      it 'successfully parses the XML' do
        expect(parsed_data).to be_a(subject)
      end

      it 'extracts plan identification elements correctly' do
        expect(parsed_data.hios_plan_and_variant_id).to eq('12345XX9876001-01')
        expect(parsed_data.plan_marketing_name).to eq('Sample Plan Name')
        expect(parsed_data.metal_level).to eq('Gold')
        expect(parsed_data.csr_variation_type).to eq('01')
      end

      it 'extracts integration indicators correctly' do
        expect(parsed_data.medical_and_drug_deductibles_integrated).to eq('Yes')
        expect(parsed_data.medical_and_drug_max_out_of_pocket_integrated).to eq('Yes')
        expect(parsed_data.is_specialist_referral_required).to eq('No')
      end
    end
  end

  describe '#to_hash' do
    context 'with complete data' do
      let(:parser) do
        parser = subject.new
        parser.hios_plan_and_variant_id = "12345XX9876001-01\n"
        parser.plan_marketing_name = "Sample Plan\n"
        parser.plan_variant_marketing_name = "Sample Variant\n"
        parser.metal_level = "Gold\n"
        parser.csr_variation_type = "01\n"
        parser.issuer_actuarial_value = "0.8\n"
        parser.av_calculator_output_number = "0.79\n"
        parser.medical_and_drug_deductibles_integrated = "Yes\n"
        parser.medical_and_drug_max_out_of_pocket_integrated = "Yes\n"
        parser.is_specialist_referral_required = "No\n"
        parser.health_care_specialist_referral_type = "PCP\n"
        parser.multiple_provider_tiers = "Yes\n"
        parser.first_tier_utilization = "0.85\n"
        parser.second_tier_utilization = "0.15\n"
        parser.default_copay_in_network = "10.00\n"
        parser.default_copay_out_of_network = "20.00\n"
        parser.default_co_insurance_in_network = "0.2\n"
        parser.default_co_insurance_out_of_network = "0.4\n"

        # Mock associations
        allow(parser).to receive_messages(maximum_out_of_pockets_attributes: [], deductible_attributes: double(to_hash: {}),
                                          hsa_attributes: double(to_hash: {}), service_visits_attributes: [], sbc_attributes: nil)

        parser
      end

      it 'returns a properly structured hash' do
        result = parser.to_hash
        expect(result).to be_a(Hash)
        expect(result).to have_key(:cost_share_variance_attributes)
        expect(result).to have_key(:maximum_out_of_pockets_attributes)
        expect(result).to have_key(:deductible_attributes)
        expect(result).to have_key(:hsa_attributes)
        expect(result).to have_key(:service_visits_attributes)
      end

      it 'cleans up whitespace in the attributes' do
        result = parser.to_hash
        expect(result[:cost_share_variance_attributes][:hios_plan_and_variant_id]).to eq('12345XX9876001-01')
        expect(result[:cost_share_variance_attributes][:plan_marketing_name]).to eq('Sample Plan')
        expect(result[:cost_share_variance_attributes][:metal_level]).to eq('Gold')
      end

      it 'includes referral information when present' do
        result = parser.to_hash
        expect(result[:cost_share_variance_attributes][:is_specialist_referral_required]).to eq('No')
        expect(result[:cost_share_variance_attributes][:health_care_specialist_referral_type]).to eq('PCP')
      end
    end

    context 'with expanded bronze metal level' do
      let(:parser) do
        parser = subject.new
        parser.metal_level = "Expanded Bronze\n"

        # Mock other required attributes

        # Mock associations
        allow(parser).to receive_messages(hios_plan_and_variant_id: '12345XX9876001-01', plan_marketing_name: 'Sample Plan',
                                          plan_variant_marketing_name: 'Sample Variant', csr_variation_type: '01', issuer_actuarial_value: '0.8',
                                          av_calculator_output_number: '0.79', medical_and_drug_deductibles_integrated: 'Yes',
                                          medical_and_drug_max_out_of_pocket_integrated: 'Yes', multiple_provider_tiers: 'Yes',
                                          first_tier_utilization: '0.85', second_tier_utilization: '0.15',
                                          default_copay_in_network: '10.00', default_copay_out_of_network: '20.00',
                                          default_co_insurance_in_network: '0.2', default_co_insurance_out_of_network: '0.4',
                                          maximum_out_of_pockets_attributes: [], deductible_attributes: double(to_hash: {}),
                                          hsa_attributes: double(to_hash: {}), service_visits_attributes: [], sbc_attributes: nil)

        parser
      end

      it 'converts expanded bronze to bronze' do
        result = parser.to_hash
        expect(result[:cost_share_variance_attributes][:metal_level]).to eq('bronze')
      end
    end

    context 'with missing optional attributes' do
      let(:parser) do
        parser = subject.new
        # Set required attributes
        parser.hios_plan_and_variant_id = "12345XX9876001-01\n"
        parser.plan_marketing_name = nil
        parser.plan_variant_marketing_name = "Sample Variant\n"
        parser.metal_level = "Gold\n"
        parser.csr_variation_type = "01\n"
        parser.medical_and_drug_deductibles_integrated = "Yes\n"
        parser.medical_and_drug_max_out_of_pocket_integrated = "Yes\n"
        parser.multiple_provider_tiers = "Yes\n"
        parser.first_tier_utilization = "0.85\n"
        parser.second_tier_utilization = "0.15\n"
        parser.default_copay_in_network = nil
        parser.default_copay_out_of_network = nil
        parser.default_co_insurance_in_network = nil
        parser.default_co_insurance_out_of_network = nil

        # Mock associations
        allow(parser).to receive_messages(maximum_out_of_pockets_attributes: [], deductible_attributes: double(to_hash: {}), hsa_attributes: nil,
                                          service_visits_attributes: [], sbc_attributes: nil)

        parser
      end

      it 'handles nil plan_marketing_name by using plan_variant_marketing_name' do
        result = parser.to_hash
        expect(result[:cost_share_variance_attributes][:plan_marketing_name]).to eq('Sample Variant')
      end

      it 'provides empty strings for nil copay/coinsurance values' do
        result = parser.to_hash
        expect(result[:cost_share_variance_attributes][:default_copay_in_network]).to eq('')
        expect(result[:cost_share_variance_attributes][:default_copay_out_of_network]).to eq('')
        expect(result[:cost_share_variance_attributes][:default_co_insurance_in_network]).to eq('')
        expect(result[:cost_share_variance_attributes][:default_co_insurance_out_of_network]).to eq('')
      end

      it 'handles nil hsa_attributes' do
        result = parser.to_hash
        expect(result[:hsa_attributes]).to eq({})
      end
    end
  end
end
