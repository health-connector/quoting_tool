# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ValueRetrievalHelper do
  # Create a test class that includes our helper module
  let(:helper_class) do
    Class.new do
      include ValueRetrievalHelper
    end
  end

  # Create an instance of the test class
  let(:helper) { helper_class.new }

  describe '#safely_retrive_value' do
    it 'returns an empty string when value is nil' do
      expect(helper.safely_retrive_value(nil)).to eq('')
    end

    it 'returns an empty string when value is an empty string' do
      expect(helper.safely_retrive_value('')).to eq('')
    end

    it 'removes newline characters from the string' do
      expect(helper.safely_retrive_value("hello\nworld")).to eq('helloworld')
    end

    it 'removes dollar signs from the string' do
      expect(helper.safely_retrive_value('$100', strip_dollar_sign: true)).to eq('100')
    end

    it 'removes both newlines and dollar signs from the string' do
      expect(helper.safely_retrive_value("$100\n$200", strip_dollar_sign: true)).to eq('100200')
    end

    it 'remove both newlines but leave dollar signs from the string' do
      expect(helper.safely_retrive_value("$100\n$200")).to eq('$100$200')
    end

    it 'trims whitespace from the string' do
      expect(helper.safely_retrive_value('  hello world  ')).to eq('hello world')
    end

    it 'handles complex cases with multiple transformations' do
      expect(helper.safely_retrive_value("  $100 \n$200  ", strip_dollar_sign: true)).to eq('100 200')
    end
  end
end
