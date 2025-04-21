# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transactions::LoadCountyZip, type: :transaction do
  let!(:subject) { Transactions::LoadCountyZip.new.call(file) }

  context 'succesful' do
    let(:file) { File.join(Rails.root, 'spec/test_data/zip_counties.xlsx') }

    it 'should be success' do
      expect(subject.success?).to eq true
    end

    it 'should create new county zip' do
      expect(Locations::CountyZip.all.size).not_to eq 0
    end

    it 'should return success message' do
      expect(subject.success[:message]).to eq 'Successfully created 5 County Zip records'
    end
  end
end
