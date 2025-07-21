# frozen_string_literal: true

module Products
  module ActuarialFactors
    # GroupSizeActuarialFactor represents pricing adjustments based on the size of an insurance group.
    #
    # Actuarial factors are multipliers used in premium calculations to adjust base rates
    # according to various risk and demographic factors. This specific implementation
    # handles adjustments based on the number of members in a group (e.g., employees in a company).
    #
    # Larger groups typically receive more favorable rates (smaller factors) due to risk spreading.
    class GroupSizeActuarialFactor < ActuarialFactor
      validates :max_integer_factor_key, numericality: { allow_blank: false }

      # Retrieves the appropriate factor value for a specific issuer, year, and group size
      # @param issuer_hios_id [String] The HIOS ID of the insurance issuer
      # @param year [Integer] The plan year
      # @param val [Integer] The group size value to look up
      # @return [Float] The actuarial factor value for the given parameters
      def self.value_for(issuer_hios_id, year, val)
        record = where(issuer_hios_id:, active_year: year).first
        record.lookup(val)
      end

      # Looks up the appropriate factor value for a given group size,
      # handling edge cases like groups that are too small or too large
      # @param val [Integer] The group size to look up
      # @return [Float] The actuarial factor value
      def lookup(val)
        max_adjusted_key = [val, max_integer_factor_key].min
        lookup_key = val < 1 ? 1 : max_adjusted_key
        super(lookup_key.to_s)
      end

      # Cached version of the lookup method for better performance
      # @param lookup_key [Integer] The group size to look up
      # @return [Float] The actuarial factor value
      def cached_lookup(lookup_key)
        max_adjusted_key = [lookup_key, max_integer_factor_key].min
        lookup_key = lookup_key < 1 ? 1 : max_adjusted_key
        super(lookup_key.to_s)
      end
    end
  end
end
