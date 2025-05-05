# frozen_string_literal: true

module Products
  module ActuarialFactors
    # Represents Standard Industrial Classification (SIC) factors used in premium calculations
    # Extends ActuarialFactor with specific lookup functionality for SIC codes
    class SicActuarialFactor < ActuarialFactor
      # Looks up a SIC factor value for a given issuer, year and SIC code
      #
      # @param issuer_hios_id [String] The HIOS ID of the issuer
      # @param year [Integer] The active year
      # @param val [String] The SIC code to look up
      # @return [Float] The factor value
      def self.value_for(issuer_hios_id, year, val)
        record = where(issuer_hios_id:, active_year: year).first
        record.lookup(val)
      end
    end
  end
end
