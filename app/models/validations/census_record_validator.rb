# frozen_string_literal: true

module Validations
  # Validates census records using Dry::Validation.
  # Ensures that required fields like date of birth and employee relationship
  # meet the necessary criteria.
  class CensusRecordValidator < Dry::Validation::Contract
    params do
      required(:dob)
      required(:employee_relationship).filled(:string)
    end

    # Validates that the date of birth is a valid Date object
    rule(:dob) do
      key.failure('is Invalid') unless value.is_a?(Date)
    end
  end
end
