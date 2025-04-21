# frozen_string_literal: true

FactoryBot.define do
  factory :dental_product, class: 'Products::DentalProduct' do
    sequence :title do |n|
      "Product #{n}"
    end

    benefit_market_kind { :aca_shop }
    application_period { Date.today.beginning_of_year..Date.today.end_of_year }
    issuer_hios_ids { ['11111'] }
    product_package_kinds { [:single_product] }
    kind { :dental }
    premium_ages { { 'min' => 14, 'max' => 64 } }
    deductible { '$0' }
    family_deductible { '$0 per person | $0 per group' }

    service_area_id { FactoryBot.create(:service_area).id }
    hsa_eligible { true }
    out_of_pocket_in_network { '$3000 per person | $6000 per group' }
    hios_id { '36046MA0770028-01' }
    hios_base_id { '36046MA0770028' }
    dental_plan_kind { :hmo }
    metal_level_kind { :dental }
  end
end
