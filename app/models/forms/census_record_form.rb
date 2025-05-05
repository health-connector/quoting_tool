# frozen_string_literal: true

module Forms
  # The CensusRecordForm handles validation and processing of individual employee census data.
  # This form is typically used when importing or manually entering employee census information.
  # It validates essential employee information and formats.
  class CensusRecordForm
    include ActiveModel::Validations
    include Virtus.model

    attribute :employer_assigned_family_id, String
    attribute :employee_relationship, String
    attribute :last_name, String
    attribute :first_name, String
    attribute :ssn, String
    attribute :dob, String

    validates :employee_relationship, :dob, presence: true
    validate :date_format

    # Validates the date of birth format
    # Adds an error if the DOB includes 'Invalid Format' text
    # @return [void]
    def date_format
      errors.add(:base, "DOB: #{dob}") if dob&.include?('Invalid Format')
    end
  end
end
