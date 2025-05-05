# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transactions::LoadRatingAreas, type: :transaction do
  let(:county_zip) { create(:county_zip, zip: '12345', county_name: 'County 1') }

  context 'succesful' do
    let(:file) { Rails.root.join('spec/test_data/rating_areas.xlsx').to_s }
    let!(:subject) { described_class.new.call(file) }

    it 'is success' do
      expect(subject.success?).to be true
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
    let!(:subject) { described_class.new.call(file) }

    it 'is failure' do
      expect(subject.failure?).to be true
    end

    it 'does not create new county zip' do
      expect(Locations::RatingArea.all.size).to eq 0
    end

    it 'returns failure message' do
      expect(subject.failure&.dig(:message)).to include('Error Updating/Creating Rating Area record for location_ids')
    end
  end

  describe '#get_location_ids' do
    let(:load_rating_areas) { described_class.new }

    context 'with valid locations' do
      it 'returns an array of county zip IDs' do
        # Create test data
        county_zip1 = double('Locations::CountyZip', _id: 'abc123')
        county_zip2 = double('Locations::CountyZip', _id: 'def456')

        # Set up expectations
        allow(Locations::CountyZip).to receive(:where)
          .with({ zip: '12345', county_name: 'County 1' })
          .and_return([county_zip1])

        allow(Locations::CountyZip).to receive(:where)
          .with({ zip: '67890', county_name: 'County 2' })
          .and_return([county_zip2])

        # Allow first method to be called on the arrays
        allow([county_zip1]).to receive(:first).and_return(county_zip1)
        allow([county_zip2]).to receive(:first).and_return(county_zip2)

        # Define test input
        locations = [
          { 'zip' => '12345', 'county_name' => 'County 1' },
          { 'zip' => '67890', 'county_name' => 'County 2' }
        ]

        # Call the method and verify result
        result = load_rating_areas.send(:get_location_ids, locations)
        expect(result).to eq(['abc123', 'def456'])
      end
    end

    context 'when some county zips are not found' do
      it 'raises an error when county zip is nil' do
        # Set up expectations for a missing county zip
        allow(Locations::CountyZip).to receive(:where)
          .with({ zip: '12345', county_name: 'Missing County' })
          .and_return([])

        # Allow first method to be called and return nil
        allow([]).to receive(:first).and_return(nil)

        # Define test input
        locations = [{ 'zip' => '12345', 'county_name' => 'Missing County' }]

        # Expect NoMethodError because nil doesn't have _id method
        expect do
          load_rating_areas.send(:get_location_ids, locations)
        end.to raise_error(NoMethodError)
      end
    end
  end

end
