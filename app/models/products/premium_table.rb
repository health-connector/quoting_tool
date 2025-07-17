# frozen_string_literal: true

# Product premium costs for a specified time period
# Effective periods:
#   DC & MA SHOP Health: Q1, Q2, Q3, Q4
#   DC Dental: annual
#   GIC Medicare: Jan-June, July-Dec
#   DC & MA IVL: annual

module Products
  # Represents a premium table for a health insurance product
  # Contains premium rates for a specific rating area and time period
  class PremiumTable
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :product, class_name: '::Products::Product'

    # The time period during which these premiums are effective
    field       :effective_period, type: Range

    # The geographic area to which these premiums apply
    belongs_to  :rating_area,
                class_name: '::Locations::RatingArea'

    # Collection of individual premium amounts by age and family composition
    embeds_many :premium_tuples,
                class_name: '::Products::PremiumTuple'

    validates :effective_period, presence: true
    # validates_presence_of :premium_tuples, :allow_blank => false

    # Finds premium tables that are effective on a given date
    # @param compare_date [Date] The date to check (defaults to current date)
    # @return [Mongoid::Criteria] Matching premium tables
    scope :effective_period_cover, lambda { |compare_date = TimeKeeper.date_of_record|
                                     where(
                                       :'effective_period.min'.lte => compare_date,
                                       :'effective_period.max'.gte => compare_date
                                     )
                                   }

    # Returns attributes to use for equality comparison
    # @return [Array<Symbol>] List of attributes to compare
    def comparable_attrs
      %i[effective_period rating_area]
    end

    # Define Comparable operator for sorting and comparison
    # If instance attributes are the same, compare PremiumTuples
    # @param other [PremiumTable] The premium table to compare against
    # @return [Integer] -1, 0, or 1 for less than, equal to, or greater than
    def <=>(other)
      if comparable_attrs.all? { |attr| send(attr) == other.send(attr) }
        if premium_tuples.to_a == other.premium_tuples.to_a
          0
        else
          premium_tuples.to_a <=> other.premium_tuples.to_a
        end
      else
        other.updated_at.blank? || (updated_at < other.updated_at) ? -1 : 1
      end
    end
  end
end
