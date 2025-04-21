# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transactions::LoadFactors, type: :transaction do
  let!(:county_zip) { FactoryBot.create(:county_zip, zip: '12345', county_name: 'County 1') }
  let!(:subject) { Transactions::LoadFactors.new.call(file) }

  describe 'sic factors' do
    context 'succesful' do
      let(:file) { File.join(Rails.root, 'spec/test_data/rating_factors.xlsx') }

      it 'should be success' do
        expect(subject.success?).to eq true
      end

      it 'should create new sic actuarial factor' do
        expect(::Products::ActuarialFactors::SicActuarialFactor.all.size).not_to eq 0
      end

      it 'should return success message' do
        expect(subject.success[:message]).to eq 'Successfully created/updated Rating Factor records'
      end
    end
  end

  describe 'group size rating factors' do
    context 'succesful' do
      let(:file) { File.join(Rails.root, 'spec/test_data/rating_factors.xlsx') }

      it 'should be success' do
        expect(subject.success?).to eq true
      end

      it 'should create new group size rating factor' do
        expect(::Products::ActuarialFactors::GroupSizeActuarialFactor.all.size).not_to eq 0
      end

      it 'should return success message' do
        expect(subject.success[:message]).to eq 'Successfully created/updated Rating Factor records'
      end
    end
  end

  describe 'participation rating factors' do
    context 'succesful' do
      let(:file) { File.join(Rails.root, 'spec/test_data/rating_factors.xlsx') }

      it 'should be success' do
        expect(subject.success?).to eq true
      end

      it 'should create new participation rating actuarial factor' do
        expect(::Products::ActuarialFactors::ParticipationRateActuarialFactor.all.size).not_to eq 0
      end

      it 'should return success message' do
        expect(subject.success[:message]).to eq 'Successfully created/updated Rating Factor records'
      end
    end
  end

  describe 'compositr rating tier factors' do
    context 'succesful' do
      let(:file) { File.join(Rails.root, 'spec/test_data/rating_factors.xlsx') }

      it 'should be success' do
        expect(subject.success?).to eq true
      end

      it 'should create new compositr rating tier actuarial factor' do
        expect(::Products::ActuarialFactors::CompositeRatingTierActuarialFactor.all.size).not_to eq 0
      end

      it 'should return success message' do
        expect(subject.success[:message]).to eq 'Successfully created/updated Rating Factor records'
      end
    end
  end
end
