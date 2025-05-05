# frozen_string_literal: true

module Locations
  # The ServiceArea model represents geographical areas where insurance products are offered.
  # Service areas define the regions where an insurance issuer's products are available to consumers.
  # Each service area may include multiple counties, zip codes, or entire states.
  class ServiceArea
    include Mongoid::Document
    include Mongoid::Timestamps

    field :active_year, type: Integer
    field :issuer_provided_title, type: String
    field :issuer_provided_code, type: String
    field :issuer_hios_id, type: String

    # The list of county-zip pairs covered by this service area
    field :county_zip_ids, type: Array

    # This service area may cover entire state(s), if it does,
    # specify which here.
    field :covered_states, type: Array

    validates :active_year, presence: { allow_blank: false }
    validates :issuer_provided_code, presence: { allow_nil: false }
    validates :issuer_hios_id, presence: { allow_nil: false }
    validate :location_specified

    index({ county_zip_ids: 1 })
    index({ covered_state_codes: 1 })

    # Validates that at least one location is specified for the service area
    # @return [Boolean] Whether the validation passes
    def location_specified
      errors.add(:base, 'a location covered by the service area must be specified') if county_zip_ids.blank? && covered_states.blank?
      true
    end

    # Finds all service areas that cover a specific address at a given point in time
    # @param address [Object] Address object with county, zip, and state attributes
    # @param during [Date] The date for which to find applicable service areas (defaults to current date)
    # @return [Array<ServiceArea>] The applicable service areas for the address
    def self.service_areas_for(address, during: TimeKeeper.date_of_record)
      county_name = address.county.blank? ? '' : address.county.titlecase
      zip_code = address.zip
      state_abbrev = address.state.blank? ? '' : address.state.upcase

      county_zip_ids = ::BenefitMarkets::Locations::CountyZip.where(
        county_name:,
        zip: zip_code,
        state: state_abbrev
      ).map(&:id).uniq

      where(
        'active_year' => during.year,
        '$or' => [
          { 'county_zip_ids' => { '$in' => county_zip_ids } },
          { 'covered_states' => state_abbrev }
        ]
      )
    end
  end
end
