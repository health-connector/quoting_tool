# frozen_string_literal: true

module Products
  module ActuarialFactors
    # Represents composite rating tier factors used in premium calculations
    # Extends ActuarialFactor with specific lookup functionality for composite rating tiers
    class CompositeRatingTierActuarialFactor < ActuarialFactor
      # Looks up a composite rating tier factor value for a given issuer, year and value
      #
      # @param issuer_hios_id [String] The HIOS ID of the issuer
      # @param year [Integer] The active year
      # @param val [String] The factor key to look up
      # @return [Float] The factor value if found, or 1.0 if not found
      def self.value_for(issuer_hios_id, year, val)
        record = where(issuer_hios_id:, active_year: year).first
        if record.present?
          record.lookup(val)
        else
          logger.error "Lookup for #{val} failed with no FactorSet found: Issuer: #{carrier_profile_id}, Year: #{year}"
          1.0
        end
      end
    end
  end
end
