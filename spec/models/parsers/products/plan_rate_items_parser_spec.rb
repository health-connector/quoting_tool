# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Parsers::Products::PlanRateItemsParser do
  describe '#to_hash' do
    let(:parser) { described_class.new }

    context 'when all fields have values with newlines and spaces' do
      before do
        parser.effective_date_value = "2023-01-01\n  "
        parser.expiration_date_value = " \n2023-12-31"
        parser.plan_id_value = "PLAN123  \n"
        parser.rate_area_id_value = "  AREA456\n  "
        parser.age_number_value = "35\n"
        parser.tobacco_value = "Y\n"
        parser.primary_enrollee_value = "100.00\n"
        parser.couple_enrollee_value = " 200.00\n"
        parser.couple_enrollee_one_dependent_value = "\n300.00"
        parser.couple_enrollee_two_dependent_value = "400.00\n "
        parser.couple_enrollee_many_dependent_value = " 500.00 \n"
        parser.primary_enrollee_one_dependent_value = " 150.00\n"
        parser.primary_enrollee_two_dependent_value = "250.00 \n"
        parser.primary_enrollee_many_dependent_value = "\n350.00\n"
        parser.effective_date = " 2023-01-01\n"
        parser.expiration_date = "2023-12-31 \n"
        parser.plan_id = "\nPLAN123"
        parser.rate_area_id = "AREA456\n "
        parser.age_number = " 35 "
        parser.tobacco = "Y\n"
        parser.primary_enrollee = "$100.00\n"
        parser.couple_enrollee = "200.00 "
        parser.couple_enrollee_one_dependent = " 300.00\n"
        parser.couple_enrollee_two_dependent = "400.00\n"
        parser.couple_enrollee_many_dependent = " 500.00 "
        parser.primary_enrollee_one_dependent = "$150.00"
        parser.primary_enrollee_two_dependent = "250.00\n"
        parser.primary_enrollee_many_dependent = " 350.00"
        parser.is_issuer_data = "true\n"
        parser.primary_enrollee_tobacco = "N \n"
        parser.primary_enrollee_tobacco_value = " 0.00\n"
      end

      it 'returns a hash with properly cleaned values' do
        result = parser.to_hash

        # Check that all values are cleaned (no newlines, properly stripped)
        expect(result[:effective_date_value]).to eq('2023-01-01')
        expect(result[:expiration_date_value]).to eq('2023-12-31')
        expect(result[:plan_id_value]).to eq('PLAN123')
        expect(result[:rate_area_id_value]).to eq('AREA456')
        expect(result[:age_number_value]).to eq('35')
        expect(result[:tobacco_value]).to eq('Y')
        expect(result[:primary_enrollee_value]).to eq('100.00')
        expect(result[:couple_enrollee_value]).to eq('200.00')
        expect(result[:couple_enrollee_one_dependent_value]).to eq('300.00')
        expect(result[:couple_enrollee_two_dependent_value]).to eq('400.00')
        expect(result[:couple_enrollee_many_dependent_value]).to eq('500.00')
        expect(result[:primary_enrollee_one_dependent_value]).to eq('150.00')
        expect(result[:primary_enrollee_two_dependent_value]).to eq('250.00')
        expect(result[:primary_enrollee_many_dependent_value]).to eq('350.00')
        expect(result[:effective_date]).to eq('2023-01-01')
        expect(result[:expiration_date]).to eq('2023-12-31')
        expect(result[:plan_id]).to eq('PLAN123')
        expect(result[:rate_area_id]).to eq('AREA456')
        expect(result[:age_number]).to eq('35')
        expect(result[:tobacco]).to eq('Y')
        expect(result[:primary_enrollee]).to eq('100.00') # Dollar sign removed
        expect(result[:couple_enrollee]).to eq('200.00')
        expect(result[:couple_enrollee_one_dependent]).to eq('300.00')
        expect(result[:couple_enrollee_two_dependent]).to eq('400.00')
        expect(result[:couple_enrollee_many_dependent]).to eq('500.00')
        expect(result[:primary_enrollee_one_dependent]).to eq('150.00') # Dollar sign removed
        expect(result[:primary_enrollee_two_dependent]).to eq('250.00')
        expect(result[:primary_enrollee_many_dependent]).to eq('350.00')
        expect(result[:is_issuer_data]).to eq('true')
        expect(result[:primary_enrollee_tobacco]).to eq('N')
        expect(result[:primary_enrollee_tobacco_value]).to eq('0.00')
      end
    end

    context 'when fields are nil' do
      it 'returns a hash with empty strings for nil values' do
        result = parser.to_hash

        # Check all fields default to empty string when nil
        expect(result[:effective_date_value]).to eq('')
        expect(result[:expiration_date_value]).to eq('')
        expect(result[:plan_id_value]).to eq('')
        expect(result[:rate_area_id_value]).to eq('')
        expect(result[:age_number_value]).to eq('')
        expect(result[:tobacco_value]).to eq('')
        expect(result[:primary_enrollee_value]).to eq('')
        expect(result[:couple_enrollee_value]).to eq('')
        expect(result[:couple_enrollee_one_dependent_value]).to eq('')
        expect(result[:couple_enrollee_two_dependent_value]).to eq('')
        expect(result[:couple_enrollee_many_dependent_value]).to eq('')
        expect(result[:primary_enrollee_one_dependent_value]).to eq('')
        expect(result[:primary_enrollee_two_dependent_value]).to eq('')
        expect(result[:primary_enrollee_many_dependent_value]).to eq('')
        expect(result[:effective_date]).to eq('')
        expect(result[:expiration_date]).to eq('')
        expect(result[:plan_id]).to eq('')
        expect(result[:rate_area_id]).to eq('')
        expect(result[:age_number]).to eq('')
        expect(result[:tobacco]).to eq('')
        expect(result[:primary_enrollee]).to eq('')
        expect(result[:couple_enrollee]).to eq('')
        expect(result[:couple_enrollee_one_dependent]).to eq('')
        expect(result[:couple_enrollee_two_dependent]).to eq('')
        expect(result[:couple_enrollee_many_dependent]).to eq('')
        expect(result[:primary_enrollee_one_dependent]).to eq('')
        expect(result[:primary_enrollee_two_dependent]).to eq('')
        expect(result[:primary_enrollee_many_dependent]).to eq('')
        expect(result[:is_issuer_data]).to eq('')
        expect(result[:primary_enrollee_tobacco]).to eq('')
        expect(result[:primary_enrollee_tobacco_value]).to eq('')
      end
    end

    context 'with mixed nil and present values' do
      before do
        parser.plan_id_value = "PLAN123\n"
        parser.primary_enrollee = "$100.00\n"
      end

      it 'properly handles a mix of nil and present values' do
        result = parser.to_hash

        # Check specific set values
        expect(result[:plan_id_value]).to eq('PLAN123')
        expect(result[:primary_enrollee]).to eq('100.00') # Dollar sign removed

        # Check a few nil values
        expect(result[:effective_date_value]).to eq('')
        expect(result[:age_number_value]).to eq('')
      end
    end
  end
end
