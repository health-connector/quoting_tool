# frozen_string_literal: true

module Products
  class DentalProduct < Product
    PRODUCT_PACKAGE_KINDS = %i[single_product multi_product].freeze
    METAL_LEVEL_KINDS     = [:dental].freeze

    field :hios_id,                     type: String
    field :hios_base_id,                type: String
    field :csr_variant_id,              type: String
    field :dental_level,                type: String
    field :dental_plan_kind,            type: Symbol

    field :hsa_eligibility,             type: Boolean,  default: false
    field :is_standard_plan,            type: Boolean,  default: false

    field :metal_level_kind,            type: Symbol
    field :ehb,                         type: Float, default: 0.0

    # Visits

    field :basic_dental_services,        type: String
    field :major_dental_services,        type: String
    field :preventive_dental_services,   type: String

    validates :metal_level_kind,
              presence: true,
              inclusion: { in: METAL_LEVEL_KINDS, message: '%<value>s is not a valid metal level kind' }

    alias is_standard_plan? is_standard_plan

    def metal_level
      dental_level.to_s
    end

    def product_type
      dental_plan_kind.to_s
    end
  end
end
