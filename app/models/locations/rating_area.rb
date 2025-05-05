# frozen_string_literal: true

module Locations
  # The RatingArea model represents geographical areas used for insurance premium calculations.
  # Rating areas are typically defined by state regulators and may include multiple counties or zip codes.
  # These rating areas determine the base premium rates that can be charged for health plans.
  class RatingArea
    include Mongoid::Document
    include Mongoid::Timestamps

    field :active_year, type: Integer
    field :exchange_provided_code, type: String

    # The list of county-zip pairs covered by this rating area
    field :county_zip_ids, type: Array

    # This rating area may cover entire state(s), if it does,
    # specify which here.
    field :covered_states, type: Array

    validates :active_year, presence: { allow_blank: false }
    validates :exchange_provided_code, presence: { allow_nil: false }

    validate :location_specified

    index({ county_zip_ids: 1 })
    index({ covered_state_codes: 1 })

    # Validates that at least one location is specified for the rating area
    # @return [Boolean] Whether the validation passes
    def location_specified
      errors.add(:base, 'a location covered by the rating area must be specified') if county_zip_ids.blank? && covered_states.blank?
      true
    end

    # Finds the rating area for a specific address at a given point in time
    # @param address [Object] Address object with county, zip, and state attributes
    # @param during [Date] The date for which to find applicable rating areas (defaults to current date)
    # @return [RatingArea] The applicable rating area for the address
    def self.rating_area_for(address, during: TimeKeeper.date_of_record)
      county_name = address.county.blank? ? '' : address.county.titlecase
      zip_code = address.zip
      state_abbrev = address.state.blank? ? '' : address.state.upcase

      county_zip_ids = ::BenefitMarkets::Locations::CountyZip.where(
        zip: zip_code,
        county_name:,
        state: state_abbrev
      ).map(&:id)

      # TODO: FIX
      # raise "Multiple Rating Areas Returned" if area.count > 1

      where(
        'active_year' => during.year,
        '$or' => [
          { 'county_zip_ids' => { '$in' => county_zip_ids } },
          { 'covered_states' => state_abbrev }
        ]
      ).first
    end
  end
end
