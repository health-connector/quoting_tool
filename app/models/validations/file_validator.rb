# frozen_string_literal: true

module Validations
  class FileValidator < Dry::Validation::Contract
    TEMPLATE_DATE = Date.new(2016, 10, 26)
    TEMPLATE_VERSION = '1.1'

    params do
      required(:template_version)
      required(:template_date)
    end

    rule(:template_version) do
      key.failure('is Invalid') if value != TEMPLATE_VERSION
    end

    rule(:template_date) do
      date = parse_date(value)
      key.failure('is Invalid') if date != TEMPLATE_DATE
    end

    private

    def parse_date(date)
      if date.is_a? Date
        date
      else
        Date.strptime(date, '%m/%d/%y')
      end
    end
  end
end
