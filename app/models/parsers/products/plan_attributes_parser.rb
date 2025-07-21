# frozen_string_literal: true

module Parsers
  module Products
    # Parses the plan attributes section from plan benefit templates
    # Contains detailed information about a specific health plan
    class PlanAttributesParser
      include HappyMapper
      include ValueRetrievalHelper

      tag 'planAttributes'

      # Plan identification elements
      element :standard_component_id, String, tag: 'standardComponentID'
      element :plan_marketing_name, String, tag: 'planMarketingName'
      element :hios_product_id, String, tag: 'hiosProductID'
      element :hpid, String, tag: 'hpid'

      # Network, service area, and formulary information
      element :network_id, String, tag: 'networkID'
      element :service_area_id, String, tag: 'serviceAreaID'
      element :formulary_id, String, tag: 'formularyID'

      # Plan classification and type information
      element :is_new_plan, String, tag: 'isNewPlan'
      element :plan_type, String, tag: 'planType'
      element :metal_level, String, tag: 'metalLevel'
      element :unique_plan_design, String, tag: 'uniquePlanDesign'
      element :qhp_or_non_qhp, String, tag: 'qhpOrNonQhp'
      element :ehb_percent_premium, String, tag: 'ehbPercentPremium'

      # Plan eligibility and coverage information
      element :insurance_plan_pregnancy_notice_req_ind, String, tag: 'insurancePlanPregnancyNoticeReqInd'
      element :is_specialist_referral_required, String, tag: 'isSpecialistReferralRequired'
      element :health_care_specialist_referral_type, String, tag: 'healthCareSpecialistReferralType'
      element :insurance_plan_benefit_exclusion_text, String, tag: 'insurancePlanBenefitExclusionText'
      element :indian_plan_variation, String, tag: 'indianPlanVariation'

      # HSA information
      element :hsa_eligibility, String, tag: 'hsaEligibility'
      element :employer_hsa_hra_contribution_indicator, String, tag: 'employerHSAHRAContributionIndicator'
      element :emp_contribution_amount_for_hsa_or_hra, String, tag: 'empContributionAmountForHSAOrHRA'

      # Child-only plan information
      element :child_only_offering, String, tag: 'childOnlyOffering'
      element :child_only_plan_id, String, tag: 'childOnlyPlanID'

      # Wellness and program offerings
      element :is_wellness_program_offered, String, tag: 'isWellnessProgramOffered'
      element :is_disease_mgmt_programs_offered, String, tag: 'isDiseaseMgmtProgramsOffered'

      # Additional plan details
      element :ehb_apportionment_for_pediatric_dental, String, tag: 'ehbApportionmentForPediatricDental'
      element :guaranteed_vs_estimated_rate, String, tag: 'guaranteedVsEstimatedRate'
      element :maximum_coinsurance_for_specialty_drugs, String, tag: 'maximumCoinsuranceForSpecialtyDrugs'
      element :max_num_days_for_charging_inpatient_copay, String, tag: 'maxNumDaysForChargingInpatientCopay'
      element :begin_primary_care_deductible_or_coinsurance_after_set_number_copays, String,
              tag: 'beginPrimaryCareDeductibleOrCoinsuranceAfterSetNumberCopays'
      element :begin_primary_care_cost_sharing_after_set_number_visits, String,
              tag: 'beginPrimaryCareCostSharingAfterSetNumberVisits'

      # Effective dates
      element :plan_effective_date, String, tag: 'planEffectiveDate'
      element :plan_expiration_date, String, tag: 'planExpirationDate'

      # Coverage area and network information
      element :out_of_country_coverage, String, tag: 'outOfCountryCoverage'
      element :out_of_country_coverage_description, String, tag: 'outOfCountryCoverageDescription'
      element :out_of_service_area_coverage, String, tag: 'outOfServiceAreaCoverage'
      element :out_of_service_area_coverage_description, String, tag: 'outOfServiceAreaCoverageDescription'
      element :national_network, String, tag: 'nationalNetwork'

      # Plan documentation URLs
      element :summary_benefit_and_coverage_url, String, tag: 'summaryBenefitAndCoverageURL'
      element :enrollment_payment_url, String, tag: 'enrollmentPaymentURL'
      element :plan_brochure, String, tag: 'planBrochure'

      # Converts the parsed plan attributes data into a structured hash format
      # @return [Hash] Clean, normalized plan attribute data
      def to_hash
        result = self.class.elements.to_h do |el|
          [el.name.to_sym, safely_retrive_value(send(el.name))]
        end
        result[:metal_level] = normalized_metal_level(result[:metal_level])
        result
      end

      private

      def normalized_metal_level(field)
        metal_level = safely_retrive_value(field)
        return 'bronze' if metal_level.downcase == 'expanded bronze'
        metal_level
      end

    end
  end
end