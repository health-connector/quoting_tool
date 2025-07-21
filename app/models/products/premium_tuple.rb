# frozen_string_literal: true

module Products
  # Represents a premium cost for a specific age
  # A collection of PremiumTuples forms a premium table for a product
  class PremiumTuple
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :premium_table,
                class_name: '::Products::PremiumTable'

    field :age,   type: Integer
    field :cost,  type: Float

    validates :age, :cost, presence: true

    default_scope -> { order(:age.asc) }

    # Returns the attributes used for comparison
    #
    # @return [Array<Symbol>] Array of attribute names for comparison
    def comparable_attrs
      %i[age cost]
    end

    # Define Comparable operator for PremiumTuples
    # If instance attributes are the same, compares by updated_at timestamp
    #
    # @param other [PremiumTuple] The other tuple to compare against
    # @return [Integer] -1, 0, or 1 depending on comparison result
    def <=>(other)
      if comparable_attrs.all? { |attr| send(attr) == other.send(attr) }
        0
      else
        other.updated_at.blank? || (updated_at < other.updated_at) ? -1 : 1
      end
    end
  end
end
