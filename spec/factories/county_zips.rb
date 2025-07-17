# frozen_string_literal: true

FactoryBot.define do
  factory :county_zip, class: 'Locations::CountyZip' do
    sequence :county_name do |n|
      "County #{n}"
    end

    sequence :zip do |n|
      11_110 + n
    end
    state { 'MA' }
  end
end
