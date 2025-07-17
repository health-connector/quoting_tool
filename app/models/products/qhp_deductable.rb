# frozen_string_literal: true

module Products
  # The QhpDeductable class represents deductible information for a specific
  # QHP cost share variance. It contains deductible amounts for different tiers,
  # network types, and coverage levels (individual vs. family).
  #
  # Deductibles are the amounts that must be paid out-of-pocket before
  # insurance begins to cover services.
  class QhpDeductable
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :qhp_cost_share_variance

    # Type of deductible (e.g., "Medical EHB Deductible", "Drug EHB Deductible")
    field :deductible_type, type: String

    # Tier 1 (preferred) in-network individual deductible amount
    field :in_network_tier_1_individual, type: String
    # Tier 1 (preferred) in-network family deductible amount
    field :in_network_tier_1_family, type: String
    # Tier 1 (preferred) in-network coinsurance percentage
    field :coinsurance_in_network_tier_1, type: String

    # Tier 2 in-network individual deductible amount
    field :in_network_tier_two_individual, type: String
    # Tier 2 in-network family deductible amount
    field :in_network_tier_two_family, type: String
    # Tier 2 in-network coinsurance percentage
    field :coinsurance_in_network_tier_2, type: String

    # Out-of-network individual deductible amount
    field :out_of_network_individual, type: String
    # Out-of-network family deductible amount
    field :out_of_network_family, type: String
    # Out-of-network coinsurance percentage
    field :coinsurance_out_of_network, type: String

    # Combined in/out-of-network individual deductible amount
    field :combined_in_or_out_network_individual, type: String
    # Combined in/out-of-network family deductible amount
    field :combined_in_or_out_network_family, type: String
    # Combined in/out-of-network tier 2 deductible amount
    field :combined_in_out_network_tier_2, type: String
  end
end
