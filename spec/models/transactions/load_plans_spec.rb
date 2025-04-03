require 'rails_helper'

RSpec.describe Transactions::LoadPlans, type: :transaction do

  let(:county_zip) { FactoryBot.create(:county_zip, zip: "12345", county_name: "County 1")}

  let(:files) {Dir.glob(File.join(Rails.root, "spec/test_data/plans", "*.xml"))}
  let(:additional_files) {Dir.glob(File.join(Rails.root, "spec/test_data/plans/2020/master_xml.xlsx"))}

  let(:product_builder) { instance_double(Operations::ProductBuilder) }
  
  before do
    allow(Operations::ProductBuilder).to receive(:new).and_return(product_builder)
    allow(product_builder).to receive(:group_size_factors).and_return({factors: {}, max_group_size: 1})
    allow(product_builder).to receive(:group_tier_factors).and_return([])
    allow(product_builder).to receive(:participation_factors).and_return({})
    allow(product_builder).to receive(:call).and_return(Dry::Monads::Success.new({message: "Success", product: double("Product")}))
  end

  context "succesful" do

    let!(:service_area) { FactoryBot.create(:service_area, county_zip_ids: [county_zip.id], active_year: 2020)}
    let!(:subject) {
      Transactions::LoadPlans.new.with_step_args(
        load_file_info: [additional_files]
      ).call(files)
    }

    it "should be success" do
      expect(subject.success?).to eq true
    end

    it "should create new health plans" do
      expect(subject.success?).to eq true
    end

    it "should create new dental plans" do
      expect(subject.success?).to eq true
    end

    it "should return success message" do
      expect(subject.success[:message]).to eq "Plans Succesfully Created"
    end
  end

  context "failure" do
    before do
      Products::Product.delete_all
    end

    let(:subject) {
      Transactions::LoadPlans.new.with_step_args(
        load_file_info: [additional_files]
      ).call(files)
    }

    it "should not create product" do
      expect(Products::Product.all.size).to eq 0
    end

    it "should still process plans but with empty service area" do
      result = subject
      expect(result.success?).to eq true
      expect(result.success[:message]).to eq "Plans Succesfully Created"
    end
  end
end
