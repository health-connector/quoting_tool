# frozen_string_literal: true

FactoryBot.define do
  factory :rating_area, class: 'Locations::RatingArea' do
    exchange_provided_code { 'R-MA001' }
    active_year { Date.today.year }
    county_zip_ids { [FactoryBot.create(:county_zip).id] }
  end
end
