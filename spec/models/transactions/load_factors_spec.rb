# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transactions::LoadFactors, type: :transaction do
  let(:county_zip) { create(:county_zip, zip: '12345', county_name: 'County 1') }
  let!(:subject) { described_class.new.call(file) }

  describe 'sic factors' do
    context 'succesful' do
      let(:file) { Rails.root.join('spec/test_data/rating_factors.xlsx').to_s }

      it 'is success' do
        expect(subject.success?).to be true
      end

      it 'creates new sic actuarial factor' do
        expect(Products::ActuarialFactors::SicActuarialFactor.all.size).not_to eq 0
      end

      it 'returns success message' do
        expect(subject.success[:message]).to eq 'Successfully created/updated Rating Factor records'
      end
    end
  end

  describe 'group size rating factors' do
    context 'succesful' do
      let(:file) { Rails.root.join('spec/test_data/rating_factors.xlsx').to_s }

      it 'is success' do
        expect(subject.success?).to be true
      end

      it 'creates new group size rating factor' do
        expect(Products::ActuarialFactors::GroupSizeActuarialFactor.all.size).not_to eq 0
      end

      it 'returns success message' do
        expect(subject.success[:message]).to eq 'Successfully created/updated Rating Factor records'
      end
    end
  end

  describe 'participation rating factors' do
    context 'succesful' do
      let(:file) { Rails.root.join('spec/test_data/rating_factors.xlsx').to_s }

      it 'is success' do
        expect(subject.success?).to be true
      end

      it 'creates new participation rating actuarial factor' do
        expect(Products::ActuarialFactors::ParticipationRateActuarialFactor.all.size).not_to eq 0
      end

      it 'returns success message' do
        expect(subject.success[:message]).to eq 'Successfully created/updated Rating Factor records'
      end
    end
  end

  describe 'compositr rating tier factors' do
    context 'succesful' do
      let(:file) { Rails.root.join('spec/test_data/rating_factors.xlsx').to_s }

      it 'is success' do
        expect(subject.success?).to be true
      end

      it 'creates new compositr rating tier actuarial factor' do
        expect(Products::ActuarialFactors::CompositeRatingTierActuarialFactor.all.size).not_to eq 0
      end

      it 'returns success message' do
        expect(subject.success[:message]).to eq 'Successfully created/updated Rating Factor records'
      end
    end
  end
end
