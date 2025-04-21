# frozen_string_literal: true

module Products
  class QhpServiceVisit
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :qhp_cost_share_variance

    field :visit_type, type: String
    field :copay_in_network_tier_1, type: String
    field :copay_in_network_tier_2, type: String
    field :copay_out_of_network, type: String
    field :co_insurance_in_network_tier_1, type: String
    field :co_insurance_in_network_tier_2, type: String
    field :co_insurance_out_of_network, type: String
  end
end
