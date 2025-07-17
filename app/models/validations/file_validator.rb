# frozen_string_literal: true

module Validations
  # Validates file metadata using Dry::Validation.
  # Ensures that files have the correct template version and date.
  class FileValidator < Dry::Validation::Contract
    # Expected template date for valid files
    TEMPLATE_DATE = Date.new(2016, 10, 26)

    # Expected template version for valid files
    TEMPLATE_VERSION = '1.1'

    params do
      required(:template_version)
      required(:template_date)
    end

    # Validates that the template version matches the expected version
    rule(:template_version) do
      key.failure('is Invalid') if value != TEMPLATE_VERSION
    end

    # Validates that the template date matches the expected date
    rule(:template_date) do
      date = parse_date(value)
      key.failure('is Invalid') if date != TEMPLATE_DATE
    end

    private

    # Parses date values into Date objects for comparison
    #
    # @param date [Date, String] Date to parse
    # @return [Date] Parsed date
    def parse_date(date)
      if date.is_a? Date
        date
      else
        Date.strptime(date, '%m/%d/%y')
      end
    end
  end
end
