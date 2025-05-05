# frozen_string_literal: true

module Products
  # The QhpBenefit class represents a specific benefit offered by a Qualified Health Plan.
  # It includes information about coverage details, limitations, and whether the benefit
  # is considered an Essential Health Benefit (EHB).
  #
  # Each QHP contains multiple benefits that describe what services are covered
  # and under what conditions.
  class QhpBenefit
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :qhp

    # Allowed reasons for EHB variance
    EhbVarianceReasonKinds = %w[above_ehb substituted substantially_equal using_alternate_benchmark
                                other_law_regulation additional_ehb_benefit dental_only_plan_available].freeze

    # Unique identifier for the benefit type
    field :benefit_type_code, type: String
    # Whether this benefit is an Essential Health Benefit
    field :is_ehb, type: String
    # Whether this benefit is required by state mandate
    field :is_state_mandate, type: String
    # Whether this benefit is covered by the plan
    field :is_benefit_covered, type: String # covered or not covered
    # Description of service limits
    field :service_limit, type: String
    # Quantitative limits on the benefit
    field :quantity_limit, type: String
    # Unit of measure for the quantity limit
    field :unit_limit, type: String # Units
    # Minimum stay requirements if applicable
    field :minimum_stay, type: String
    # Exclusions that apply to this benefit
    field :exclusion, type: String
    # Additional explanations about the benefit
    field :explanation, type: String

    # Reason for variance from standard EHB
    field :ehb_variance_reason, type: String

    ## Deductable and Out of Pocket Expenses
    # Whether subject to tier 1 deductible
    field :subject_to_deductible_tier_1, type: String
    # Whether subject to tier 2 deductible
    field :subject_to_deductible_tier_2, type: String
    # Whether excluded from in-network maximum out-of-pocket
    field :excluded_in_network_moop, type: String
    # Whether excluded from out-of-network maximum out-of-pocket
    field :excluded_out_of_network_moop, type: String
  end
end
