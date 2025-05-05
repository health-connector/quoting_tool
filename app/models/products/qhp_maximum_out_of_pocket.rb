# frozen_string_literal: true

module Products
  # The QhpMaximumOutOfPocket class represents the maximum out-of-pocket (MOOP) limits
  # for a specific QHP cost share variance. These are the maximum amounts a consumer
  # will have to pay for covered services in a plan year.
  #
  # Maximum out-of-pocket limits include deductibles, coinsurance, copayments,
  # and similar charges, but not premiums.
  class QhpMaximumOutOfPocket
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :qhp_cost_share_variance

    # Name or type of the MOOP (e.g., "Medical EHB MOOP", "Drug EHB MOOP")
    field :name, type: String

    # Tier 1 (preferred) in-network individual MOOP amount
    field :in_network_tier_1_individual_amount, type: String
    # Tier 1 (preferred) in-network family MOOP amount
    field :in_network_tier_1_family_amount, type: String

    # Tier 2 in-network individual MOOP amount
    field :in_network_tier_2_individual_amount, type: String
    # Tier 2 in-network family MOOP amount
    field :in_network_tier_2_family_amount, type: String

    # Out-of-network individual MOOP amount
    field :out_of_network_individual_amount, type: String
    # Out-of-network family MOOP amount
    field :out_of_network_family_amount, type: String

    # Combined in/out-of-network individual MOOP amount
    field :combined_in_out_network_individual_amount, type: String
    # Combined in/out-of-network family MOOP amount
    field :combined_in_out_network_family_amount, type: String
  end
end
