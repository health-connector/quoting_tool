# frozen_string_literal: true

module Parsers
  module Products
    # ServiceVisitsParser parses XML data for service visits information
    # This class maps XML elements to Ruby attributes for medical service visit data
    class ServiceVisitsParser
      include HappyMapper

      tag 'serviceVisit'

      element :visit_type, String, tag: 'visitType'
      element :copay_in_network_tier_1, String, tag: 'copayInNetworkTier1'
      element :copay_in_network_tier_2, String, tag: 'copayInNetworkTier2'
      element :copay_out_of_network, String, tag: 'copayOutOfNetwork'
      element :co_insurance_in_network_tier_1, String, tag: 'coInsuranceInNetworkTier1'
      element :co_insurance_in_network_tier_2, String, tag: 'coInsuranceInNetworkTier2'
      element :co_insurance_out_of_network, String, tag: 'coInsuranceOutOfNetwork'

      # Converts parsed service visit data to a normalized hash
      #
      # @return [Hash] normalized data with cleaned string values
      def to_hash
        {
          visit_type: visit_type.gsub("\n", '').strip,
          copay_in_network_tier_1: copay_in_network_tier_1.gsub("\n", '').strip,
          copay_in_network_tier_2: copay_in_network_tier_2.present? ? copay_in_network_tier_2.gsub("\n", '').strip : '',
          copay_out_of_network: copay_out_of_network.gsub("\n", '').strip,
          co_insurance_in_network_tier_1: co_insurance_in_network_tier_1.gsub("\n", '').strip,
          co_insurance_in_network_tier_2: if co_insurance_in_network_tier_2.present?
                                            co_insurance_in_network_tier_2.gsub(
                                              "\n", ''
                                            ).strip
                                          else
                                            ''
                                          end,
          co_insurance_out_of_network: co_insurance_out_of_network.gsub("\n", '').strip
        }
      end
    end
  end
end
