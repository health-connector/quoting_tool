# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transactions::LoadRatingAreas, type: :transaction do
  let!(:county_zip) { FactoryBot.create(:county_zip, zip: '12345', county_name: 'County 1') }

  context 'succesful' do
    let(:file) { Rails.root.join('spec/test_data/rating_areas.xlsx').to_s }
    let!(:subject) { Transactions::LoadRatingAreas.new.call(file) }

    it 'is success' do
      expect(subject.success?).to eq true
    end

    it 'creates new rating area' do
      expect(Locations::RatingArea.all.size).not_to eq 0
    end

    it 'returns success message' do
      expect(subject.success[:message]).to eq 'Successfully created/updated 1 Rating Area records'
    end
  end

  context 'failure' do
    # Ensure we have a clean database for this context
    before do
      Locations::RatingArea.delete_all
    end

    let(:file) { Rails.root.join('spec/test_data/invalid_rating_areas.xlsx').to_s }
    let!(:subject) { Transactions::LoadRatingAreas.new.call(file) }

    it 'is failure' do
      expect(subject.failure?).to eq true
    end

    it 'does not create new county zip' do
      expect(Locations::RatingArea.all.size).to eq 0
    end

    it 'returns failure message' do
      expect(subject.failure&.dig(:message)).to include('Error creating Rating Area')
    end
  end
end
