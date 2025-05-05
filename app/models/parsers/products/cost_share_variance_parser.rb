# frozen_string_literal: true

module Parsers
  module Products
    # Parses the cost share variance element from plan benefit templates
    # Cost Share Variance contains the specific cost-sharing structure for a plan,
    # including deductibles, maximum out of pocket amounts, and service visit costs.
    class CostShareVarianceParser
      include HappyMapper

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
      def to_hash
        response = {
          cost_share_variance_attributes: {
            hios_plan_and_variant_id: hios_plan_and_variant_id.gsub("\n", '').strip,
            plan_marketing_name: if plan_marketing_name.present?
                                   plan_marketing_name.gsub("\n",
                                                            '').strip
                                 else
                                   plan_variant_marketing_name.gsub(
                                     "\n", ''
                                   ).strip
                                 end,
            metal_level: if metal_level.gsub("\n",
                                             '').strip.downcase == 'expanded bronze'
                           'bronze'
                         else
                           metal_level.gsub("\n",
                                            '').strip
                         end,
            csr_variation_type: csr_variation_type.gsub("\n", '').strip,
            issuer_actuarial_value: begin
              issuer_actuarial_value.gsub("\n", '').strip
            rescue StandardError
              ''
            end,
            av_calculator_output_number: begin
              av_calculator_output_number.gsub("\n", '').strip
            rescue StandardError
              ''
            end,
            medical_and_drug_deductibles_integrated: medical_and_drug_deductibles_integrated.gsub("\n", '').strip,
            medical_and_drug_max_out_of_pocket_integrated: medical_and_drug_max_out_of_pocket_integrated.gsub("\n",
                                                                                                              '').strip,
            multiple_provider_tiers: multiple_provider_tiers.gsub("\n", '').strip,
            first_tier_utilization: first_tier_utilization.gsub("\n", '').strip,
            second_tier_utilization: second_tier_utilization.gsub("\n", '').strip,
            default_copay_in_network: if default_copay_in_network.present?
                                        default_copay_in_network.gsub("\n",
                                                                      '').strip
                                      else
                                        ''
                                      end,
            default_copay_out_of_network: if default_copay_out_of_network.present?
                                            default_copay_out_of_network.gsub(
                                              "\n", ''
                                            ).strip
                                          else
                                            ''
                                          end,
            default_co_insurance_in_network: if default_co_insurance_in_network.present?
                                               default_co_insurance_in_network.gsub(
                                                 "\n", ''
                                               ).strip
                                             else
                                               ''
                                             end,
            default_co_insurance_out_of_network: if default_co_insurance_out_of_network.present?
                                                   default_co_insurance_out_of_network.gsub(
                                                     "\n", ''
                                                   ).strip
                                                 else
                                                   ''
                                                 end
          },
          maximum_out_of_pockets_attributes: maximum_out_of_pockets_attributes.map(&:to_hash),
          deductible_attributes: deductible_attributes.to_hash,
          hsa_attributes: hsa_attributes.present? ? hsa_attributes.to_hash : {},
          service_visits_attributes: service_visits_attributes.map(&:to_hash)
        }
        response[:sbc_attributes] = sbc_attributes.to_hash if sbc_attributes
        if is_specialist_referral_required.present?
          response[:cost_share_variance_attributes].merge!(
            is_specialist_referral_required: is_specialist_referral_required.gsub("\n", '').strip
          )
        end
        if health_care_specialist_referral_type.present?
          response[:cost_share_variance_attributes].merge!(
            health_care_specialist_referral_type: health_care_specialist_referral_type.gsub("\n", '').strip
          )
        end
        response
      end
    end
  end
end
