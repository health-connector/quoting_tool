# frozen_string_literal: true

module Validations
  class CensusRecordValidator < Dry::Validation::Contract
    params do
      required(:dob)
      required(:employee_relationship).filled(:string)
    end

    rule(:dob) do
      key.failure('is Invalid') unless value.is_a?(Date)
    end
  end
end
