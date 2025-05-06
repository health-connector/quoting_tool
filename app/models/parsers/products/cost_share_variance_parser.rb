# frozen_string_literal: true

module Parsers
  module Products
    # Parses the cost share variance element from plan benefit templates
    # Cost Share Variance contains the specific cost-sharing structure for a plan,
    # including deductibles, maximum out of pocket amounts, and service visit costs.
    class CostShareVarianceParser
      include HappyMapper
      include ValueRetrievalHelper

      tag 'costShareVariance'

      # Plan identification elements
      element :hios_plan_and_variant_id, String, tag: 'planId'
      element :plan_marketing_name, String, tag: 'planMarketingName'
      element :plan_variant_marketing_name, String, tag: 'planVariantMarketingName'
      element :metal_level, String, tag: 'metalLevel'
      element :csr_variation_type, String, tag: 'csrVariationType'
      element :issuer_actuarial_value, String, tag: 'issuerActuarialValue'
      element :av_calculator_output_number, String, tag: 'avCalculatorOutputNumber'

      # Integration indicators
      element :medical_and_drug_deductibles_integrated, String, tag: 'medicalAndDrugDeductiblesIntegrated'
      element :medical_and_drug_max_out_of_pocket_integrated, String, tag: 'medicalAndDrugMaxOutOfPocketIntegrated'
      element :is_specialist_referral_required, String, tag: 'isSpecialistReferralRequired'
      element :health_care_specialist_referral_type, String, tag: 'isSpecialistReferralRequired'

      # Provider tier information
      element :multiple_provider_tiers, String, tag: 'multipleProviderTiers'
      element :first_tier_utilization, String, tag: 'firstTierUtilization'
      element :second_tier_utilization, String, tag: 'secondTierUtilization'

      # Default cost sharing values
      element :default_copay_in_network, String, tag: 'defaultCopayInNetwork'
      element :default_copay_out_of_network, String, tag: 'defaultCopayOutOfNetwork'
      element :default_co_insurance_in_network, String, tag: 'defaultCoInsuranceInNetwork'
      element :default_co_insurance_out_of_network, String, tag: 'defaultCoInsuranceOutOfNetwork'

      # Related components
      has_one :sbc_attributes, Parsers::Products::SbcParser, tag: 'sbc', dependent: :destroy
      has_many :maximum_out_of_pockets_attributes, Parsers::Products::MaximumOutOfPocketsParser, tag: 'moop', deep: true, dependent: :destroy
      has_one :deductible_attributes, Parsers::Products::DeductibleParser, tag: 'planDeductible', deep: true, dependent: :destroy
      has_many :service_visits_attributes, Parsers::Products::ServiceVisitsParser, tag: 'serviceVisit', deep: true, dependent: :destroy
      has_one :hsa_attributes, Parsers::Products::HsaParser, tag: 'hsa', deep: true, dependent: :destroy

      # Converts the parsed data into a structured hash format
      # @return [Hash] Hash containing nested cost share variance attributes and related components
      # def to_hash
      #   {
      #     cost_share_variance_attributes: elements_to_hash
      #   }
      # end

      # def elements_to_hash
      #   self.class.elements.to_h do |el|
      #     [el.name.to_sym, safely_retrive_value(send(el.name))]
      #   end
      # end
      def to_hash
        {
          cost_share_variance_attributes: {
            hios_plan_and_variant_id: safely_retrive_value(hios_plan_and_variant_id),
            plan_marketing_name: safely_retrive_value((plan_marketing_name.presence || plan_variant_marketing_name)),
            metal_level: normalized_metal_level(metal_level),
            csr_variation_type: safely_retrive_value(csr_variation_type),
            issuer_actuarial_value: safely_retrive_value(issuer_actuarial_value),
            av_calculator_output_number: safely_retrive_value(av_calculator_output_number),
            medical_and_drug_deductibles_integrated: safely_retrive_value(medical_and_drug_deductibles_integrated),
            medical_and_drug_max_out_of_pocket_integrated: safely_retrive_value(medical_and_drug_max_out_of_pocket_integrated),
            multiple_provider_tiers: safely_retrive_value(multiple_provider_tiers),
            first_tier_utilization: safely_retrive_value(first_tier_utilization),
            second_tier_utilization: safely_retrive_value(second_tier_utilization),
            default_copay_in_network: safely_retrive_value(default_copay_in_network),
            default_copay_out_of_network: safely_retrive_value(default_copay_out_of_network),
            default_co_insurance_in_network: safely_retrive_value(default_co_insurance_in_network),
            default_co_insurance_out_of_network: safely_retrive_value(default_co_insurance_out_of_network),
            is_specialist_referral_required: safely_retrive_value(is_specialist_referral_required),
            health_care_specialist_referral_type: safely_retrive_value(health_care_specialist_referral_type)
          },
          **hash_attributes
        }
      end

      def hash_attributes
        {
          maximum_out_of_pockets_attributes: maximum_out_of_pockets_attributes.map(&:to_hash),
          deductible_attributes: deductible_attributes.to_hash,
          hsa_attributes: hsa_attributes.present? ? hsa_attributes.to_hash : {},
          service_visits_attributes: service_visits_attributes.map(&:to_hash),
          sbc_attributes: sbc_attributes.present? ? sbc_attributes.to_hash : {}
        }
      end

      def normalized_metal_level(field)
        metal_level = safely_retrive_value(field)
        return 'bronze' if metal_level.downcase == 'expanded bronze'
        metal_level
      end

    end
  end
end
