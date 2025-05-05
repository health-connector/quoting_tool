# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::ProductBuilder, type: :operation do
  # Keep this test super simple - focus on the public API, not implementation details

  let(:product_builder) { described_class.new }

  before do
    # Mock all methods that cause issues
    allow(product_builder).to receive_messages(group_size_factors: { factors: {}, max_group_size: 1 },
                                               group_tier_factors: [], participation_factors: {}, parse_market: 'shop')
  end

  context 'successful' do
    let(:service_area) { create(:service_area, issuer_provided_code: '11111') }

    let(:qhp) do
      instance_double(Products::Qhp,
                      active_year: Time.zone.today.year,
                      issuer_id: '11111',
                      service_area_id: 'MAS001',
                      metal_level: 'Silver',
                      plan_type: 'HMO',
                      ehb_percent_premium: 0.9,
                      hsa_eligibility: false,
                      dental_plan_only_ind: 'No',
                      market_coverage: 'SHOP',
                      qhp_cost_share_variances: [])
    end

    let(:variance) do
      instance_double(Products::QhpCostShareVariance,
                      hios_plan_and_variant_id: '12345XX1234567-01',
                      plan_marketing_name: 'Test Plan',
                      qhp_service_visits: [],
                      product_id: nil)
    end

    let(:service_area_map) do
      { [service_area.issuer_provided_code, 'MAS001', Time.zone.today.year] => service_area.id }
    end

    let(:health_data_map) do
      { ['12345XX1234567', Time.zone.today.year] => {
        hios_id: '12345XX1234567',
        provider_directory_url: '',
        year: Time.zone.today.year,
        rx_formulary_url: '',
        is_standard_plan: true,
        network_information: 'Test network info',
        title: 'Standard Silver Plan',
        product_package_kinds: %i[single_product single_issuer]
      } }
    end

    let(:dental_data_map) { {} }

    before do
      # Setup our test
      allow(qhp).to receive(:qhp_cost_share_variances).and_return([variance])
      allow(variance).to receive(:product_id=)

      # Mock all the service visit lookups
      service_visit = instance_double(Products::QhpServiceVisit,
                                      copay_in_network_tier_1: '$25 In Network',
                                      co_insurance_in_network_tier_1: '20%')
      allow(variance).to receive(:qhp_service_visits).with(hash_including(:visit_type)).and_return([service_visit])

      # Mock deductable
      deductable = instance_double(Products::QhpDeductable,
                                   in_network_tier_1_individual: '$2000',
                                   in_network_tier_1_family: '$4000')

      # Mock maximum out of pocket
      max_out_of_pocket = instance_double(Products::QhpMaximumOutOfPocket,
                                          in_network_tier_1_family_amount: '$10000')
      allow(variance).to receive_messages(qhp_service_visits: [], qhp_deductable: deductable,
                                          qhp_maximum_out_of_pockets: [max_out_of_pocket])

      # Mock the visit value parsing
      allow(product_builder).to receive_messages(retrieve_metal_level: 'silver',
                                                 health_product?: true,
                                                 pcp_in_network_copay: '25',
                                                 hospital_stay_in_network_copay: '25.00',
                                                 emergency_in_network_copay: '25',
                                                 drug_in_network_copay: '25',
                                                 out_of_pocket_in_network: '10000',
                                                 service_visit_co_insurance: '20')

      # Mock saving the product - use a double instead of any_instance_of
      health_product = instance_double(Products::HealthProduct, save!: true, id: BSON::ObjectId.new)
      allow(Products::HealthProduct).to receive(:new).and_return(health_product)
      allow(health_product).to receive(:issuer_hios_ids=)

      # Mock the product lookup to be empty (so it creates a new one)
      allow(Products::Product).to receive(:where).and_return([])
    end

    it 'returns a success monad' do
      params = {
        qhp:,
        health_data_map:,
        dental_data_map:,
        service_area_map:
      }

      result = product_builder.call(params)
      expect(result).to be_success
      expect(result.success[:message]).to eq 'Successfully created/updated Plan records'
    end
  end

  context 'without service area' do
    it 'sets service_area_id to nil' do
      product = Products::HealthProduct.new({
                                              service_area_id: nil,
                                              metal_level_kind: :silver,
                                              benefit_market_kind: 'aca_shop',
                                              application_period: (Date.new(Time.zone.today.year, 1,
                                                                            1)..Date.new(Time.zone.today.year, 12, 31)),
                                              title: 'Test Product'
                                            })
      expect(product).not_to be_nil
      expect(product.service_area_id).to be_nil
    end
  end
end
