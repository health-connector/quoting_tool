# frozen_string_literal: true

module Products
  module ActuarialFactors
    # Represents participation rate factors used in premium calculations
    # Extends ActuarialFactor with specialized handling for participation rate values
    class ParticipationRateActuarialFactor < ActuarialFactor
      # Looks up a participation rate factor value for a given issuer, year and value
      #
      # @param issuer_hios_id [String] The HIOS ID of the issuer
      # @param year [Integer] The active year
      # @param val [Numeric] The participation rate value to look up
      # @return [Float] The factor value
      def self.value_for(issuer_hios_id, year, val)
        record = where(issuer_hios_id:, active_year: year).first
        record.lookup(val)
      end

      # Looks up a participation rate factor value with specialized handling
      #
      # @param val [Numeric] The participation rate value (0-100 scale, not 0-1)
      # @return [Float] The factor value
      # @note Expects a number out of 100, NOT a fraction out of 1.
      #       97.1234 is OK, 0.971234 is NOT
      def lookup(val)
        rounded_value = val.respond_to?(:round) ? val.round : val
        transformed_value = [rounded_value, 1].max
        super(transformed_value.to_s)
      end

      # Performs a cached lookup with specialized handling for participation rates
      #
      # @param val [Numeric] The participation rate value (0-100 scale, not 0-1)
      # @return [Float] The factor value
      def cached_lookup(val)
        rounded_value = val.respond_to?(:round) ? val.round : val
        transformed_value = [rounded_value, 1].max
        super(transformed_value.to_s)
      end
    end
  end
end
