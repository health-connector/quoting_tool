# frozen_string_literal: true

FactoryBot.define do
  factory :service_area, class: 'Locations::ServiceArea' do
    active_year { Date.today.year }
    issuer_provided_code { 'MAS001' }
    issuer_hios_id { '11111' }
    issuer_provided_title { 'Issuer Provided Title' }
    county_zip_ids { [FactoryBot.create(:county_zip).id] }
  end
end
