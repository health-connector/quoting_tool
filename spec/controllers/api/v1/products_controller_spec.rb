require 'rails_helper'

RSpec.describe Api::V1::ProductsController do
  let(:county_name) { "Suffolk" }
  let(:zip_code) { "02108" }
  let(:state) { "MA" }
  let(:sic_code) { "0112" }
  let(:start_date) { Date.today.beginning_of_month }
  
  describe "#plans" do
    let(:base_params) do
      {
        sic_code: sic_code, 
        start_date: start_date, 
        county_name: county_name, 
        zip_code: zip_code, 
        state: state
      }
    end
    
    # Mock data for responses
    let(:health_metal_level) { "platinum" }
    let(:dental_metal_level) { "high" }
    let(:health_data) { [{'metal_level' => health_metal_level}] }
    let(:dental_data) { [{'metal_level' => dental_metal_level}] }
    
    # Setup shared controller mocks
    before do
      allow(Rails.cache).to receive(:read).and_return(nil)
      allow(Rails.cache).to receive(:write).and_return(true)
    end
    
    context "when requesting health plans" do
      before do
        # Mock the controller's interactions with the database
        allow(controller).to receive(:plans).and_call_original
        allow(controller).to receive(:service_area_ids).and_return([BSON::ObjectId.new])
        allow(controller).to receive(:rating_area_id).and_return(BSON::ObjectId.new)
        allow(controller).to receive(:county_zips).and_return([BSON::ObjectId.new])
        
        # Mock Products::Product.where
        health_products = [double('HealthProduct')]
        allow(Products::Product).to receive(:where).and_return(health_products)
        
        # Mock the serializer
        serialized_data = {data: {attributes: {'metal_level' => health_metal_level}}}
        allow_any_instance_of(ProductSerializer).to receive(:serializable_hash).and_return(serialized_data)
        
        get :plans, params: base_params.merge(kind: "health")
      end
      
      it "returns HTTP success" do
        expect(response).to have_http_status(:success)
      end
      
      it "returns JSON with success status" do
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["status"]).to eq "success"
      end
      
      it "returns products with correct metal level" do
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["plans"][0]['metal_level']).to eq health_metal_level
      end
    end
    
    context "when requesting dental plans" do
      before do
        # Mock the controller's interactions with the database
        allow(controller).to receive(:plans).and_call_original
        allow(controller).to receive(:service_area_ids).and_return([BSON::ObjectId.new])
        allow(controller).to receive(:rating_area_id).and_return(BSON::ObjectId.new)
        allow(controller).to receive(:county_zips).and_return([BSON::ObjectId.new])
        
        # Mock Products::Product.where
        dental_products = [double('DentalProduct')]
        allow(Products::Product).to receive(:where).and_return(dental_products)
        
        # Mock the serializer
        serialized_data = {data: {attributes: {'metal_level' => dental_metal_level}}}
        allow_any_instance_of(ProductSerializer).to receive(:serializable_hash).and_return(serialized_data)
        
        get :plans, params: base_params.merge(kind: "dental")
      end
      
      it "returns HTTP success" do
        expect(response).to have_http_status(:success)
      end
      
      it "returns JSON with success status" do
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["status"]).to eq "success"
      end
      
      it "returns products with correct metal level" do
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["plans"][0]['metal_level']).to eq dental_metal_level
      end
    end
  end
  
  describe "#sbc_document" do
    context "when successful" do
      before do
        success_result = Dry::Monads::Success.new({document: "sample_data"})
        allow_any_instance_of(Transactions::SbcDocument).to receive(:call).and_return(success_result)
        get :sbc_document, params: {key: "some_key"}
      end
      
      it "returns success status" do
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["status"]).to eq "success"
      end
      
      it "returns metadata" do
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key("metadata")
      end
    end
    
    context "when unsuccessful" do
      before do
        failure_result = Dry::Monads::Failure.new("error")
        allow_any_instance_of(Transactions::SbcDocument).to receive(:call).and_return(failure_result)
        get :sbc_document, params: {key: "invalid_key"}
      end
      
      it "returns failure status" do
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["status"]).to eq "failure"
      end
      
      it "returns empty metadata" do
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["metadata"]).to eq ""
      end
    end
  end
end
