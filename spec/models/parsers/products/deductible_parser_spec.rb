# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Parsers::Products::DeductibleParser do
  describe 'parsing XML' do
    let(:xml_data) do
      <<~XML
        <planDeductible>
          <deductibleType>Medical and Rx\n</deductibleType>
          <inNetworkTier1Individual>$500\n</inNetworkTier1Individual>
          <inNetworkTier1Family>$1,000\n</inNetworkTier1Family>
          <coinsuranceInNetworkTier1>20%\n</coinsuranceInNetworkTier1>
          <inNetworkTierTwoIndividual>$1,000\n</inNetworkTierTwoIndividual>
          <inNetworkTierTwoFamily>$2,000\n</inNetworkTierTwoFamily>
          <coinsuranceInNetworkTier2>30%\n</coinsuranceInNetworkTier2>
          <outOfNetworkIndividual>$2,000\n</outOfNetworkIndividual>
          <outOfNetworkFamily>$4,000\n</outOfNetworkFamily>
          <coinsuranceOutofNetwork>40%\n</coinsuranceOutofNetwork>
          <combinedInOrOutNetworkIndividual>$3,000\n</combinedInOrOutNetworkIndividual>
          <combinedInOrOutNetworkFamily>$6,000\n</combinedInOrOutNetworkFamily>
          <combinedInOrOutTier2>Yes\n</combinedInOrOutTier2>
        </planDeductible>
      XML
    end

    let(:parser) { described_class.parse(xml_data, single: true) }

    it 'parses deductible_type correctly' do
      expect(parser.deductible_type).to eq "Medical and Rx\n"
    end

    it 'parses in_network_tier_1_individual correctly' do
      expect(parser.in_network_tier_1_individual).to eq "$500\n"
    end

    it 'parses in_network_tier_1_family correctly' do
      expect(parser.in_network_tier_1_family).to eq "$1,000\n"
    end

    it 'parses coinsurance_in_network_tier_1 correctly' do
      expect(parser.coinsurance_in_network_tier_1).to eq "20%\n"
    end

    it 'parses in_network_tier_two_individual correctly' do
      expect(parser.in_network_tier_two_individual).to eq "$1,000\n"
    end

    it 'parses in_network_tier_two_family correctly' do
      expect(parser.in_network_tier_two_family).to eq "$2,000\n"
    end

    it 'parses coinsurance_in_network_tier_2 correctly' do
      expect(parser.coinsurance_in_network_tier_2).to eq "30%\n"
    end

    it 'parses out_of_network_individual correctly' do
      expect(parser.out_of_network_individual).to eq "$2,000\n"
    end

    it 'parses out_of_network_family correctly' do
      expect(parser.out_of_network_family).to eq "$4,000\n"
    end

    it 'parses coinsurance_out_of_network correctly' do
      expect(parser.coinsurance_out_of_network).to eq "40%\n"
    end

    it 'parses combined_in_or_out_network_individual correctly' do
      expect(parser.combined_in_or_out_network_individual).to eq "$3,000\n"
    end

    it 'parses combined_in_or_out_network_family correctly' do
      expect(parser.combined_in_or_out_network_family).to eq "$6,000\n"
    end

    it 'parses combined_in_out_network_tier_2 correctly' do
      expect(parser.combined_in_out_network_tier_2).to eq "Yes\n"
    end
  end

  describe '#to_hash' do
    context 'with all fields present' do
      let(:parser) do
        parser = described_class.new
        parser.deductible_type = "Medical and Rx\n"
        parser.in_network_tier_1_individual = "$500\n"
        parser.in_network_tier_1_family = "$1,000\n"
        parser.coinsurance_in_network_tier_1 = "20%\n"
        parser.in_network_tier_two_individual = "$1,000\n"
        parser.in_network_tier_two_family = "$2,000\n"
        parser.coinsurance_in_network_tier_2 = "30%\n"
        parser.out_of_network_individual = "$2,000\n"
        parser.out_of_network_family = "$4,000\n"
        parser.coinsurance_out_of_network = "40%\n"
        parser.combined_in_or_out_network_individual = "$3,000\n"
        parser.combined_in_or_out_network_family = "$6,000\n"
        parser.combined_in_out_network_tier_2 = "Yes\n"
        parser
      end

      it 'returns a hash with clean values' do
        result = parser.to_hash

        expect(result[:deductible_type]).to eq "Medical and Rx"
        expect(result[:in_network_tier_1_individual]).to eq "$500"
        expect(result[:in_network_tier_1_family]).to eq "$1,000"
        expect(result[:coinsurance_in_network_tier_1]).to eq "20%"
        expect(result[:in_network_tier_two_individual]).to eq "$1,000"
        expect(result[:in_network_tier_two_family]).to eq "$2,000"
        expect(result[:coinsurance_in_network_tier_2]).to eq "30%"
        expect(result[:out_of_network_individual]).to eq "$2,000"
        expect(result[:out_of_network_family]).to eq "$4,000"
        expect(result[:coinsurance_out_of_network]).to eq "40%"
        expect(result[:combined_in_or_out_network_individual]).to eq "$3,000"
        expect(result[:combined_in_or_out_network_family]).to eq "$6,000"
        expect(result[:combined_in_out_network_tier_2]).to eq "Yes"
      end
    end

    context 'with some fields missing' do
      let(:parser) do
        parser = described_class.new
        parser.deductible_type = "Medical Only\n"
        parser.in_network_tier_1_individual = "$500\n"
        parser.in_network_tier_1_family = "$1,000\n"
        parser.coinsurance_in_network_tier_1 = "20%\n"
        parser.out_of_network_individual = "$2,000\n"
        parser.out_of_network_family = "$4,000\n"
        parser.combined_in_or_out_network_individual = "$3,000\n"
        parser.combined_in_or_out_network_family = "$6,000\n"
        parser
      end

      before do
        allow(parser).to receive_messages(in_network_tier_two_individual: nil, in_network_tier_two_family: nil, coinsurance_in_network_tier_2: nil,
                                          coinsurance_out_of_network: nil, combined_in_out_network_tier_2: nil)
      end

      it 'handles nil values correctly' do
        result = parser.to_hash

        expect(result[:in_network_tier_two_individual]).to eq ""
        expect(result[:in_network_tier_two_family]).to eq ""
        expect(result[:coinsurance_in_network_tier_2]).to eq ""
        expect(result[:coinsurance_out_of_network]).to eq ""
        expect(result[:combined_in_out_network_tier_2]).to eq ""
      end
    end

    context 'with empty string values' do
      let(:parser) do
        parser = described_class.new
        parser.deductible_type = "Medical Only\n"
        parser.in_network_tier_1_individual = "$500\n"
        parser.in_network_tier_1_family = "$1,000\n"
        parser.coinsurance_in_network_tier_1 = "20%\n"
        parser.in_network_tier_two_individual = ""
        parser.in_network_tier_two_family = ""
        parser.coinsurance_in_network_tier_2 = ""
        parser.out_of_network_individual = "$2,000\n"
        parser.out_of_network_family = "$4,000\n"
        parser.coinsurance_out_of_network = ""
        parser.combined_in_or_out_network_individual = "$3,000\n"
        parser.combined_in_or_out_network_family = "$6,000\n"
        parser.combined_in_out_network_tier_2 = ""
        parser
      end

      it 'handles empty string values correctly' do
        result = parser.to_hash

        expect(result[:in_network_tier_two_individual]).to eq ""
        expect(result[:in_network_tier_two_family]).to eq ""
        expect(result[:coinsurance_in_network_tier_2]).to eq ""
        expect(result[:coinsurance_out_of_network]).to eq ""
        expect(result[:combined_in_out_network_tier_2]).to eq ""
      end
    end
  end
end
