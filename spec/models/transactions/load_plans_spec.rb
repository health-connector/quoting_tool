require 'rails_helper'

RSpec.describe Transactions::LoadPlans, type: :transaction do

  let(:county_zip) { FactoryBot.create(:county_zip, zip: "12345", county_name: "County 1")}

  let(:files) {Dir.glob(File.join(Rails.root, "spec/test_data/plans", "*.xml"))}
  let(:additional_files) {Dir.glob(File.join(Rails.root, "spec/test_data/plans/2020/master_xml.xlsx"))}

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
      expect(Products::HealthProduct.all.size).not_to eq 0
    end

    it "should create new dental plans" do
      expect(Products::DentalProduct.all.size).not_to eq 0
    end

    it "should return success message" do
      expect(subject.success[:message]).to eq "Plans Succesfully Created"
    end
  end

  context "failure" do

    let(:subject) {
      Transactions::LoadPlans.new.with_step_args(
        load_file_info: [additional_files]
      ).call(files)
    } # No Service Area mapped

    it "should not create product" do
      expect(Products::Product.all.size).to eq 0
    end

    it "should still process plans but with empty service area" do
      result = subject
      expect(result.success?).to eq true
      expect(result.success[:message]).to eq "Plans Succesfully Created"
      products = Products::Product.all
      products.each do |product|
        expect(product.service_area_id).to be_nil
      end
    end
  end
end
