# frozen_string_literal: true

module Parsers
  module Products
    # Parses the deductible information from plan benefit templates
    # Contains details about plan deductibles including in-network, out-of-network,
    # individual, family and tiered deductible amounts and related coinsurance values
    class DeductibleParser
      include HappyMapper
      include ValueRetrievalHelper

      tag 'planDeductible'

      # General deductible information
      element :deductible_type, String, tag: 'deductibleType'

      # Tier 1 network deductible information
      element :in_network_tier_1_individual, String, tag: 'inNetworkTier1Individual'
      element :in_network_tier_1_family, String, tag: 'inNetworkTier1Family'
      element :coinsurance_in_network_tier_1, String, tag: 'coinsuranceInNetworkTier1'

      # Tier 2 network deductible information
      element :in_network_tier_two_individual, String, tag: 'inNetworkTierTwoIndividual'
      element :in_network_tier_two_family, String, tag: 'inNetworkTierTwoFamily'
      element :coinsurance_in_network_tier_2, String, tag: 'coinsuranceInNetworkTier2'

      # Out-of-network deductible information
      element :out_of_network_individual, String, tag: 'outOfNetworkIndividual'
      element :out_of_network_family, String, tag: 'outOfNetworkFamily'
      element :coinsurance_out_of_network, String, tag: 'coinsuranceOutofNetwork'

      # Combined network deductible information
      element :combined_in_or_out_network_individual, String, tag: 'combinedInOrOutNetworkIndividual'
      element :combined_in_or_out_network_family, String, tag: 'combinedInOrOutNetworkFamily'
      element :combined_in_out_network_tier_2, String, tag: 'combinedInOrOutTier2'

      # Converts the parsed deductible data into a structured hash format
      # @return [Hash] Clean, normalized deductible attributes
      def to_hash
        self.class.elements.to_h do |el|
          [el.name.to_sym, safely_retrive_value(send(el.name))]
        end
      end
    end
  end
end
