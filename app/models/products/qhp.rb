# frozen_string_literal: true

module Products
  # The Qhp class represents a Qualified Health Plan as defined in the Affordable Care Act.
  # It contains detailed information about the plan structure, benefits, and metadata
  # required for ACA compliance and reporting.
  #
  # QHPs include both medical and dental products with their specific characteristics,
  # cost sharing structures, and variant information.
  class Qhp
    include Mongoid::Document
    include Mongoid::Timestamps
    # include CsvOperater

    # Template version for the QHP data format
    field :template_version, type: String
    # ID of the issuer offering this QHP
    field :issuer_id, type: String
    # State postal code where the QHP is offered
    field :state_postal_code, type: String
    # Full state name where the QHP is offered
    field :state_postal_name, type: String
    # Market coverage type (e.g., individual, small group)
    field :market_coverage, type: String
    # Whether this is a standalone dental plan
    field :dental_plan_only_ind, type: String
    # Tax Identification Number
    field :tin, type: String
    # Application identifier
    field :application_id, type: String

    # Standard component ID - 14 characters
    field :standard_component_id, type: String
    # Marketing name of the plan
    field :plan_marketing_name, type: String

    # 10 character HIOS product ID
    field :hios_product_id, type: String
    # Health Plan ID
    field :hpid, type: String
    # Network identifier
    field :network_id, type: String
    # Service area identifier
    field :service_area_id, type: String
    # Formulary identifier for prescription drugs
    field :formulary_id, type: String

    # Plan attributes
    # Indicates if this is a new plan offering
    field :is_new_plan, type: String
    # Plan type (e.g., HMO, PPO, POS, EPO, Indemnity)
    field :plan_type, type: String
    # Metal level (e.g., Bronze, Silver, Gold, Platinum)
    field :metal_level, type: String
    # Indicates if this plan has a unique design
    field :unique_plan_design, type: String
    # Whether the plan is offered on-exchange, off-exchange, or both
    field :qhp_or_non_qhp, type: String
    # Whether pregnancy notice is required
    field :insurance_plan_pregnancy_notice_req_ind, type: String
    # Whether specialist referral is required
    field :is_specialist_referral_required, type: String
    # Type of specialist referral required
    field :health_care_specialist_referral_type, type: String, default: ''
    # Exclusion text describing what isn't covered
    field :insurance_plan_benefit_exclusion_text, type: String
    # Percentage of premium attributable to Essential Health Benefits
    field :ehb_percent_premium, type: String

    # Whether this is an Indian plan variation
    field :indian_plan_variation, type: String

    # Required fields for small group plans
    # Whether the plan is HSA eligible
    field :hsa_eligibility, type: String
    # Whether employer contributes to HSA/HRA
    field :employer_hsa_hra_contribution_indicator, type: String
    # Amount of employer HSA/HRA contribution
    field :emp_contribution_amount_for_hsa_or_hra, type: Money

    # Whether the plan is available for children only, adults only, or both
    field :child_only_offering, type: String
    # ID of the child-only plan variant
    field :child_only_plan_id, type: String
    # Whether a wellness program is offered
    field :is_wellness_program_offered, type: String
    # Whether disease management programs are offered
    field :is_disease_mgmt_programs_offered, type: String, default: ''

    ## Stand alone dental
    # Dollar amount for pediatric dental EHB apportionment
    field :ehb_apportionment_for_pediatric_dental, type: String
    # Whether rates are guaranteed or estimated
    field :guaranteed_vs_estimated_rate # guaranteed_rate, estimated_rate

    ## AV Calculator Additional Benefit Design
    # Maximum coinsurance for specialty drugs
    field :maximum_coinsurance_for_specialty_drugs, type: String

    # Maximum number of days for charging inpatient copay (1-10)
    field :max_num_days_for_charging_inpatient_copay, type: String
    # Whether primary care deductible/coinsurance begins after set number of copays
    field :begin_primary_care_deductible_or_coinsurance_after_set_number_copays, type: String
    # Whether primary care cost sharing begins after set number of visits
    field :begin_primary_care_cost_sharing_after_set_number_visits, type: String

    ## Plan Dates
    # Start date of plan availability
    field :plan_effective_date, type: Date
    # End date of plan availability
    field :plan_expiration_date, type: Date
    # Calendar year for which the plan is active
    field :active_year, type: Integer

    ## Geographic Coverage
    # Whether the plan covers services outside the US
    field :out_of_country_coverage, type: String
    # Description of out-of-country coverage
    field :out_of_country_coverage_description, type: String
    # Whether the plan covers services outside service area
    field :out_of_service_area_coverage, type: String
    # Description of out-of-service-area coverage
    field :out_of_service_area_coverage_description, type: String
    # Whether the plan has a nationwide network
    field :national_network, type: String

    ## URLs
    # Link to Summary of Benefits and Coverage document
    field :summary_benefit_and_coverage_url, type: String
    # Link for enrollment/payment
    field :enrollment_payment_url, type: String
    # Link to plan brochure
    field :plan_brochure, type: String

    # Reference to associated Plan object
    field :plan_id, type: BSON::ObjectId

    validates :issuer_id, :state_postal_code, :standard_component_id, :plan_marketing_name, :hios_product_id,
              :network_id, :service_area_id, :is_new_plan, :plan_type, :metal_level,
              :qhp_or_non_qhp, :emp_contribution_amount_for_hsa_or_hra, :child_only_offering,
              :plan_effective_date, :out_of_country_coverage, :out_of_service_area_coverage,
              :national_network, presence: true

    scope :by_hios_ids_and_active_year, ->(sc_id, year) { where(:standard_component_id.in => sc_id, active_year: year) }

    # Benefits covered by this QHP
    embeds_many :qhp_benefits,
                class_name: 'Products::QhpBenefit',
                cascade_callbacks: true,
                validate: true

    # Cost sharing variations for this QHP
    embeds_many :qhp_cost_share_variances,
                class_name: 'Products::QhpCostShareVariance',
                cascade_callbacks: true,
                validate: true

    accepts_nested_attributes_for :qhp_benefits, :qhp_cost_share_variances

    # Database indexes for improved query performance
    index({ 'issuer_id' => 1 })
    index({ 'state_postal_code' => 1 })
    index({ 'national_network' => 1 })
    index({ 'tin' => 1 }, { sparse: true })
    index({ 'qhp_benefits.benefit_type_code' => 1 })
    index({ 'standard_component_id' => 1, 'active_year' => 1 })

    # Associates a Plan object with this QHP
    # @param new_plan [Plan] The Plan to associate
    # @raise [ArgumentError] If new_plan is not a Plan object
    def plan=(new_plan)
      raise ArgumentError, 'expected Plan' unless new_plan.is_a? Plan

      self.plan_id = new_plan._id
      @plan = new_plan
    end

    # Retrieves the associated Plan object
    # @return [Plan, nil] The associated Plan or nil if not set
    def plan
      return @plan if defined? @plan

      @plan = Plan.find(plan_id) if plan_id.present?
    end

    # Types of visits for medical plans
    VISIT_TYPES = [
      'Primary Care Visit to Treat an Injury or Illness',
      'Urgent Care Centers or Facilities',
      'Specialist Visit',
      'Emergency Room Services',
      'Inpatient Hospital Services (e.g., Hospital Stay)',
      'Laboratory Outpatient and Professional Services',
      'X-rays and Diagnostic Imaging',
      'Generic Drugs',
      'Preferred Brand Drugs',
      'Non-Preferred Brand Drugs',
      'Specialty Drugs'
    ].freeze

    # Types of visits for dental plans
    DENTAL_VISIT_TYPES = [
      'Routine Dental Services (Adult)',
      'Dental Check-Up for Children',
      'Basic Dental Care - Child',
      'Orthodontia - Child',
      'Major Dental Care - Child',
      'Basic Dental Care - Adult',
      'Orthodontia - Adult',
      'Major Dental Care - Adult',
      'Accidental Dental'
    ].freeze

    # Creates a mapping of plans to their HSA eligibility status
    # @param plans [Array<Plan>] List of plans to map
    # @return [Hash] Mapping of plan IDs to HSA eligibility
    def self.plan_hsa_status_map(plans)
      plan_hsa_status = {}
      @hios_ids = plans.map(&:hios_id)
      @year = plans.first.present? ? plans.first.active_year : ''
      qcsvs = fetch_cost_share_variances
      qcsvs.map { |qcsv| plan_hsa_status[qcsv.plan.id.to_s] = qcsv.qhp.hsa_eligibility }

      plan_hsa_status
    end

    # Retrieves QHP cost share variances for the specified plans and year
    # @return [Array<QhpCostShareVariance>] List of cost share variances
    def self.fetch_cost_share_variances
      Rails.cache.fetch("csvs-hios-ids-#{@hios_ids}-year-#{@year}", expires_in: 5.hours) do
        Products::QhpCostShareVariance.find_qhp_cost_share_variances(@hios_ids, @year, '')
      end
    end
  end
end
