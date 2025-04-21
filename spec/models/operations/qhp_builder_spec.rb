# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Operations::QhpBuilder, type: :operation do
  describe '#call' do
    context 'when processing QHP data' do
      let(:qhp_builder) { Operations::QhpBuilder.new }
      let(:product_builder) { instance_double(Operations::ProductBuilder) }

      before do
        allow(Operations::ProductBuilder).to receive(:new).and_return(product_builder)
        allow(product_builder).to receive(:call)
          .and_return(Dry::Monads::Success.new({ message: 'Success' }))

        qhp_double = double('Qhp',
                            :plan_effective_date => Date.today,
                            :plan_effective_date= => nil,
                            :plan_expiration_date= => nil,
                            :attributes= => nil,
                            :hsa_eligibility= => nil,
                            :save! => true,
                            :qhp_benefits => [],
                            :qhp_benefits= => nil,
                            :qhp_cost_share_variances => [],
                            :qhp_cost_share_variances= => nil,
                            :standard_component_id => '99999XX9999999',
                            :active_year => Date.today.year)

        allow(Products::Qhp).to receive(:where).and_return([])
        allow(Products::Qhp).to receive(:new).and_return(qhp_double)

        allow(qhp_builder).to receive(:build_objects).and_return(true)
        allow(qhp_builder).to receive(:validate_and_persist_qhp).and_return(true)
      end

      it 'returns a success monad with appropriate message' do
        current_year = Date.today.year
        input = {
          packages: [
            {
              header: { issuer_id: '12345' },
              plans_list: {
                plans: [
                  {
                    plan_attributes: {
                      plan_effective_date: "1/1/#{current_year}",
                      standard_component_id: '12345XX1234567',
                      service_area_id: 'MAS001'
                    },
                    cost_share_variance_list_attributes: []
                  }
                ]
              },
              benefits_list: { benefits: [] }
            }
          ]
        }

        result = qhp_builder.call(input)

        expect(result).to be_success
        expect(result.success[:message]).to eq 'Successfully created/updated QHP records'
      end
    end
  end
end
