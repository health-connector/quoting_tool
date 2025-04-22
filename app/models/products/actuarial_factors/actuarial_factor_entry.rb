# frozen_string_literal: true

module Products
  module ActuarialFactors
    class ActuarialFactorEntry
      include Mongoid::Document

      embedded_in :actuarial_factors, class_name: '::Products::ActuarialFactors::ActuarialFactor'

      field :factor_key, type: String
      field :factor_value, type: Float

      validates :factor_value, numericality: { allow_blank: false }
      validates :factor_key, presence: { allow_blank: false }
    end
  end
end
