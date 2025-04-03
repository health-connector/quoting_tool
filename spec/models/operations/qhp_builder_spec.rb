require 'rails_helper'

RSpec.describe Operations::QhpBuilder, type: :operation do
  describe "#call" do
    # Keep this test super simple - focus on the public API, not implementation details
    context "when processing QHP data" do
      let(:qhp_builder) { Operations::QhpBuilder.new }
      
      # Setup before each example
      before do
        # Prevent any actual DB operations or complex setup
        # We're going to mock everything needed for the public API of the class
        allow_any_instance_of(Operations::ProductBuilder).to receive(:call)
          .and_return(Dry::Monads::Success.new({message: "Success"}))
        
        # We need to mock all used methods on the Qhp class
        # But we'll do it in a minimal way - just mock what the interface expects
        qhp_double = double("Qhp", 
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
                          :standard_component_id => "99999XX9999999",
                          :active_year => Date.today.year)
        
        allow(Products::Qhp).to receive(:where).and_return([])
        allow(Products::Qhp).to receive(:new).and_return(qhp_double)
        
        # The key thing: stub out the internal methods we don't care about testing
        allow(qhp_builder).to receive(:build_objects).and_return(true)
        allow(qhp_builder).to receive(:validate_and_persist_qhp).and_return(true)
      end
      
      it "returns a success monad with appropriate message" do
        # Define simple valid input with required fields
        current_year = Date.today.year
        input = { 
          packages: [
            { 
              header: { issuer_id: "12345" },
              plans_list: { 
                plans: [
                  { 
                    plan_attributes: {
                      plan_effective_date: "1/1/#{current_year}",
                      standard_component_id: "12345XX1234567",
                      service_area_id: "MAS001"
                    },
                    cost_share_variance_list_attributes: []
                  }
                ] 
              },
              benefits_list: { benefits: [] }
            }
          ]
        }
        
        # Execute the public method
        result = qhp_builder.call(input)
        
        # Assert on the public response
        expect(result).to be_success
        expect(result.success[:message]).to eq "Successfully created/updated QHP records"
      end
    end
  end
end
