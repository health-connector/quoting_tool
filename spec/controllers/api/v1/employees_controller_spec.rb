# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::EmployeesController do
  describe '#start_on_dates' do
    let(:health_product) { create(:health_product, service_area_id: service_area.id) }
    let(:dental_product) { create(:dental_product, service_area_id: service_area.id) }
    let!(:rating_area) { create(:rating_area, county_zip_ids: [county_zip.id]) }
    let(:service_area) { create(:service_area, county_zip_ids: [county_zip.id]) }
    let(:county_zip) { create(:county_zip) }

    let!(:premium_tuples) do
      (1..65).map do |age|
        Products::PremiumTuple.new(
          age:,
          cost: age
        )
      end
    end

    let(:mock_registry) do
      instance_double(ResourceRegistry::Registry).tap do |registry|
        allow(registry).to receive(:resolve).with('aca_shop_market.open_enrollment.minimum_length_days').and_return(10)
        allow(registry).to receive(:resolve).with('aca_shop_market.open_enrollment.monthly_end_on').and_return(15)
        allow(registry).to receive(:resolve).with('aca_shop_market.open_enrollment.maximum_length_months').and_return(2)
        allow(registry).to receive(:resolve).with(
          'aca_shop_market.initial_application.earliest_start_prior_to_effective_on_months'
        ).and_return(3)
      end
    end

    let(:premium_tables) do
      Products::Product.all.health_products.each do |product|
        product.premium_tables << Products::PremiumTable.new(
          effective_period: Date.new(2020, 4, 1)..Date.new(2020, 6, 1),
          rating_area_id: rating_area.id,
          premium_tuples:
        )
        product.premium_ages = premium_tuples.map(&:age).minmax
        product.save!
      end
    end

    before do
      allow(ResourceRegistry::Registry).to receive(:new).and_return(mock_registry)
      allow(Date).to receive(:today).and_return(Date.new(2020, 6, 15)) # Mock current date
    end

    context 'when rates are not available for projected month' do
      before do
        allow(controller).to receive(:rates_for?).and_return({
                                                               '2020-08-01' => false,
                                                               '2020-09-01' => false
                                                             })

        get :start_on_dates
      end

      it 'returns success' do
        expect(response).to have_http_status(:success)
      end

      it 'returns empty set for dates' do
        parsed_response = response.parsed_body
        expect(parsed_response['dates']).to eq []
        expect(parsed_response['is_late_rate']).to be true
      end
    end

    context 'when rates are available for projected month' do
      before do
        allow(controller).to receive(:rates_for?).and_return({
                                                               '2020-08-01' => true,
                                                               '2020-09-01' => true
                                                             })

        get :start_on_dates
      end

      it 'returns success' do
        expect(response).to have_http_status(:success)
      end

      it 'returns set for dates' do
        parsed_response = response.parsed_body
        expect(parsed_response['dates']).to eq ['2020/08/01', '2020/09/01']
        expect(parsed_response['is_late_rate']).to be false
      end
    end
  end
end
