module Locations
  class CountyZip
    include Mongoid::Document
    include Mongoid::Timestamps

    field :county_name, type: String
    field :zip, type: String
    field :state, type: String

    index({ state: 1, county_name: 1, zip: 1 })
  end
end
