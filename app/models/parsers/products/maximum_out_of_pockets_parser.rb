# frozen_string_literal: true

module Parsers
  module Products
    # Parses the Maximum Out of Pocket (MOOP) information from plan benefit templates
    # Contains details about maximum out-of-pocket costs across different network tiers
    class MaximumOutOfPocketsParser
      include HappyMapper

      tag 'moop'

      # MOOP identification
      element :name, String, tag: 'name'

      # Tier 1 network MOOP information
      element :in_network_tier_1_individual_amount, String, tag: 'inNetworkTier1IndividualAmount'
      element :in_network_tier_1_family_amount, String, tag: 'inNetworkTier1FamilyAmount'

      # Tier 2 network MOOP information
      element :in_network_tier_2_individual_amount, String, tag: 'inNetworkTier2IndividualAmount'
      element :in_network_tier_2_family_amount, String, tag: 'inNetworkTier2FamilyAmount'

      # Out-of-network MOOP information
      element :out_of_network_individual_amount, String, tag: 'outOfNetworkIndividualAmount'
      element :out_of_network_family_amount, String, tag: 'outOfNetworkFamilyAmount'

      # Combined network MOOP information
      element :combined_in_out_network_individual_amount, String, tag: 'combinedInOutNetworkIndividualAmount'
      element :combined_in_out_network_family_amount, String, tag: 'combinedInOutNetworkFamilyAmount'

      # Converts the parsed MOOP data into a structured hash format
      # @return [Hash] Clean, normalized MOOP attributes
      # @note Fixes variable name mismatch between in_network_tier_2_individual_amount
      # and in_network_tier2_individual_amount
      def to_hash
        {
          name: name.gsub("\n", '').strip,
          in_network_tier_1_individual_amount: in_network_tier_1_individual_amount.gsub("\n", '').strip,
          in_network_tier_1_family_amount: in_network_tier_1_family_amount.gsub("\n", '').strip,
          in_network_tier_2_individual_amount: if in_network_tier_2_individual_amount.present?
                                                 in_network_tier_2_individual_amount.gsub(
                                                   "\n", ''
                                                 ).strip
                                               else
                                                 ''
                                               end,
          in_network_tier_2_family_amount: if in_network_tier_2_family_amount.present?
                                             in_network_tier_2_family_amount.gsub(
                                               "\n", ''
                                             ).strip
                                           else
                                             ''
                                           end,
          out_of_network_individual_amount: out_of_network_individual_amount.gsub("\n", '').strip,
          out_of_network_family_amount: out_of_network_family_amount.gsub("\n", '').strip,
          combined_in_out_network_individual_amount: combined_in_out_network_individual_amount.gsub("\n", '').strip,
          combined_in_out_network_family_amount: combined_in_out_network_family_amount.gsub("\n", '').strip
        }
      end
    end
  end
end
