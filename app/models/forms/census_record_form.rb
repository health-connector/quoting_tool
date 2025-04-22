# frozen_string_literal: true

module Forms
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

    def date_format
      errors.add(:base, "DOB: #{dob}") if dob&.include?('Invalid Format')
    end
  end
end
