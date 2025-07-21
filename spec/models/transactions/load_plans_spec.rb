# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transactions::LoadPlans, type: :transaction do
  let(:county_zip) { create(:county_zip, zip: '12345', county_name: 'County 1') }

  let(:files) { Dir.glob(Rails.root.join('spec/test_data/plans/*.xml').to_s) }
  let(:additional_files) { Dir.glob(Rails.root.join('spec/test_data/plans/2020/master_xml.xlsx').to_s) }

  let(:product_builder) { instance_double(Operations::ProductBuilder) }

  before do
    allow(Operations::ProductBuilder).to receive(:new).and_return(product_builder)
    allow(product_builder).to receive_messages(
      group_size_factors: {
        factors: {},
        max_group_size: 1
      },
      group_tier_factors: [],
      participation_factors: {},
      call: Dry::Monads::Success.new({ message: 'Success', product: double('Product') })
    )
  end

  context 'succesful' do
    let(:service_area) { create(:service_area, county_zip_ids: [county_zip.id], active_year: 2020) }
    let!(:subject) do
      described_class.new.with_step_args(
        load_file_info: [additional_files]
      ).call(files)
    end

    it 'is success' do
      expect(subject.success?).to be true
    end

    it 'creates new health plans' do
      expect(subject.success?).to be true
    end

    it 'creates new dental plans' do
      expect(subject.success?).to be true
    end

    it 'returns success message' do
      expect(subject.success[:message]).to eq 'Plans Succesfully Created'
    end
  end

  context 'failure' do
    before do
      Products::Product.delete_all
    end

    let(:subject) do
      described_class.new.with_step_args(
        load_file_info: [additional_files]
      ).call(files)
    end

    it 'does not create product' do
      expect(Products::Product.all.size).to eq 0
    end

    it 'stills process plans but with empty service area' do
      result = subject
      expect(result.success?).to be true
      expect(result.success[:message]).to eq 'Plans Succesfully Created'
    end
  end
end
