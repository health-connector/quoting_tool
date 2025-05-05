# frozen_string_literal: true

module Locations
  # The CountyZip model represents geographical location data at the county and zip code level.
  # This data is used for determining service areas, rating areas, and other location-based calculations.
  class CountyZip
    include Mongoid::Document
    include Mongoid::Timestamps

    field :county_name, type: String
    field :zip, type: String
    field :state, type: String

    # Index for efficient lookups by state, county, and zip
    index({ state: 1, county_name: 1, zip: 1 })
  end
end
