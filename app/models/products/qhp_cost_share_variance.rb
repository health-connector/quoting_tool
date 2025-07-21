# frozen_string_literal: true

module Products
  # The QhpCostShareVariance class represents a variation of a Qualified Health Plan
  # with specific cost sharing structures. This includes different metal levels,
  # CSR (Cost Sharing Reduction) variations, and associated premium and deductible information.
  #
  # Cost share variances are particularly important for Silver plans, which have
  # different variations based on income level for subsidized enrollees.
  class QhpCostShareVariance
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :qhp

    # HIOS ID plus variant ID (e.g., "12345GA001-01")
    field :hios_plan_and_variant_id, type: String
    # Marketing name of the plan
    field :plan_marketing_name, type: String
    # Metal level (Bronze, Silver, Gold, Platinum)
    field :metal_level, type: String
    # Type of CSR variation (e.g., "94", "87", "73", "00")
    field :csr_variation_type, type: String
    # Reference to the product this variance belongs to
    field :product_id, type: String

    # Issuer's calculated actuarial value
    field :issuer_actuarial_value, type: String
    # Output from the AV Calculator
    field :av_calculator_output_number, type: String

    # Whether medical and drug deductibles are integrated
    field :medical_and_drug_deductibles_integrated, type: String
    # Whether medical and drug maximum out-of-pocket limits are integrated
    field :medical_and_drug_max_out_of_pocket_integrated, type: String
    # Whether specialist referral is required
    field :is_specialist_referral_required, type: String
    # Type of specialist referral
    field :health_care_specialist_referral_type, type: String
    # Whether the plan uses multiple provider tiers
    field :multiple_provider_tiers, type: String
    # First tier utilization percentage
    field :first_tier_utilization, type: String
    # Second tier utilization percentage
    field :second_tier_utilization, type: String

    # Default copay amount for in-network services
    field :default_copay_in_network, type: String
    # Default copay amount for out-of-network services
    field :default_copay_out_of_network, type: String
    # Default coinsurance percentage for in-network services
    field :default_co_insurance_in_network, type: String
    # Default coinsurance percentage for out-of-network services
    field :default_co_insurance_out_of_network, type: String

    ## SBC Scenario - Having a Baby
    field :having_baby_deductible, type: String
    field :having_baby_co_payment, type: String
    field :having_baby_co_insurance, type: String
    field :having_baby_limit, type: String

    ## SBC Scenario - Managing Diabetes
    field :having_diabetes_deductible, type: String
    field :having_diabetes_copay, type: String
    field :having_diabetes_co_insurance, type: String
    field :having_diabetes_limit, type: String

    # Deductible information for this cost share variance
    embeds_one :qhp_deductable,
               class_name: 'Products::QhpDeductable',
               cascade_callbacks: true,
               validate: true

    # Maximum out-of-pocket information for this cost share variance
    embeds_many :qhp_maximum_out_of_pockets,
                class_name: 'Products::QhpMaximumOutOfPocket',
                cascade_callbacks: true,
                validate: true

    # Service visit information for this cost share variance
    embeds_many :qhp_service_visits,
                class_name: 'Products::QhpServiceVisit',
                cascade_callbacks: true,
                validate: true

    accepts_nested_attributes_for :qhp_maximum_out_of_pockets, :qhp_service_visits

    # Finds QHP records by HIOS IDs and active year
    # @param ids [Array<String>] HIOS IDs to search for
    # @param year [Integer] Year to filter by
    # @return [Array<Qhp>] Matching QHP records
    def self.find_qhp(ids, year)
      Products::Qhp.by_hios_ids_and_active_year(ids.pluck(0..13), year)
    end

    # Finds QHP cost share variances by HIOS IDs, year, and coverage kind
    # @param ids [Array<String>] HIOS IDs to search for
    # @param year [Integer] Year to filter by
    # @param coverage_kind [String] Coverage type (e.g., "health", "dental")
    # @return [Array<QhpCostShareVariance>] Matching cost share variances
    def self.find_qhp_cost_share_variances(ids, year, coverage_kind)
      csvs = find_qhp(ids, year).map(&:qhp_cost_share_variances).flatten
      ids = ids.map { |a| "#{a}-01" } if coverage_kind == 'dental'
      csvs.select { |a| ids.include?(a.hios_plan_and_variant_id) }
    end

    # Retrieves the associated product
    # @return [BenefitMarkets::Products::Product] Associated product
    def product
      if product_id.present?
        ::BenefitMarkets::Products::Product.find(product_id)
      else
        Rails.cache.fetch("qcsv-product-#{qhp.active_year}-hios-id-#{hios_plan_and_variant_id}", expires_in: 5.hours) do
          BenefitMarkets::Products::Product.where(hios_id: /#{hios_plan_and_variant_id}/).select do |a|
            a.active_year == qhp.active_year
          end.first
        end
      end
    end
  end
end
