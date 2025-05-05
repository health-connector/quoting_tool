# frozen_string_literal: true

module Products
  # The QhpServiceVisit class represents cost-sharing information for specific types
  # of medical services (e.g., primary care visits, specialist visits, ER visits)
  # within a QHP cost share variance.
  #
  # This includes copay and coinsurance amounts for different network tiers.
  class QhpServiceVisit
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :qhp_cost_share_variance

    # Type of service visit (e.g., "Primary Care Visit", "Specialist Visit")
    field :visit_type, type: String

    # Fixed copay amount for tier 1 in-network visits
    field :copay_in_network_tier_1, type: String
    # Fixed copay amount for tier 2 in-network visits
    field :copay_in_network_tier_2, type: String
    # Fixed copay amount for out-of-network visits
    field :copay_out_of_network, type: String

    # Coinsurance percentage for tier 1 in-network visits
    field :co_insurance_in_network_tier_1, type: String
    # Coinsurance percentage for tier 2 in-network visits
    field :co_insurance_in_network_tier_2, type: String
    # Coinsurance percentage for out-of-network visits
    field :co_insurance_out_of_network, type: String
  end
end
