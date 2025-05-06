# frozen_string_literal: true

module Parsers
  module Products
    # PlanRateItemsParser is responsible for parsing individual rate items within plan rates.
    # These items define the pricing details for different enrollment scenarios, age brackets,
    # tobacco usage, and other factors that affect insurance premium calculations.
    #
    # Each rate item contains both the original values and the derived computed values,
    # which are typically denoted with a *_value suffix.
    class PlanRateItemsParser
      include HappyMapper
      include ValueRetrievalHelper

      tag 'items'

      # Date range fields
      element :effective_date_value, String, tag: 'effectiveDateValue'
      element :expiration_date_value, String, tag: 'expirationDateValue'

      # Plan identification fields
      element :plan_id_value, String, tag: 'planIdValue'
      element :rate_area_id_value, String, tag: 'rateAreaIdValue'

      # Rating factors
      element :age_number_value, String, tag: 'ageNumberValue'
      element :tobacco_value, String, tag: 'tobaccoValue'

      # Premium rate fields for different enrollment scenarios
      element :primary_enrollee_value, String, tag: 'primaryEnrolleeValue'
      element :couple_enrollee_value, String, tag: 'coupleEnrolleeValue'
      element :couple_enrollee_one_dependent_value, String, tag: 'coupleEnrolleeOneDependentValue'
      element :couple_enrollee_two_dependent_value, String, tag: 'coupleEnrolleeTwoDependentValue'
      element :couple_enrollee_many_dependent_value, String, tag: 'coupleEnrolleeManyDependentValue'
      element :primary_enrollee_one_dependent_value, String, tag: 'primaryEnrolleeOneDependentValue'
      element :primary_enrollee_two_dependent_value, String, tag: 'primaryEnrolleeTwoDependentValue'
      element :primary_enrollee_many_dependent_value, String, tag: 'primaryEnrolleeManyDependentValue'

      # Corresponding fields without _value suffix (may represent processed values)
      element :effective_date, String, tag: 'effectiveDate'
      element :expiration_date, String, tag: 'expirationDate'
      element :plan_id, String, tag: 'planId'
      element :rate_area_id, String, tag: 'rateAreaId'
      element :age_number, String, tag: 'ageNumber'
      element :tobacco, String, tag: 'tobacco'
      element :primary_enrollee, String, tag: 'primaryEnrollee'
      element :couple_enrollee, String, tag: 'coupleEnrollee'
      element :couple_enrollee_one_dependent, String, tag: 'coupleEnrolleeOneDependent'
      element :couple_enrollee_two_dependent, String, tag: 'coupleEnrolleeTwoDependent'
      element :couple_enrollee_many_dependent, String, tag: 'coupleEnrolleeManyDependent'
      element :primary_enrollee_one_dependent, String, tag: 'primaryEnrolleeOneDependent'
      element :primary_enrollee_two_dependent, String, tag: 'primaryEnrolleeTwoDependent'
      element :primary_enrollee_many_dependent, String, tag: 'primaryEnrolleeManyDependent'

      # Additional metadata
      element :is_issuer_data, String, tag: 'isIssuerData'
      element :primary_enrollee_tobacco, String, tag: 'primaryEnrolleeTobacco'
      element :primary_enrollee_tobacco_value, String, tag: 'primaryEnrolleeTobaccoValue'

      # Converts the parsed rate items to a standardized hash format,
      # cleaning and normalizing all text fields
      # @return [Hash] Structured and sanitized rate item data
      def to_hash
        {
          effective_date_value: safely_retrive_value(effective_date_value),
          expiration_date_value: safely_retrive_value(expiration_date_value),
          plan_id_value: safely_retrive_value(plan_id_value),
          rate_area_id_value: safely_retrive_value(rate_area_id_value),
          age_number_value: safely_retrive_value(age_number_value),
          tobacco_value: safely_retrive_value(tobacco_value),
          primary_enrollee_value: safely_retrive_value(primary_enrollee_value),
          primary_enrollee_one_dependent_value: safely_retrive_value(primary_enrollee_one_dependent_value),
          primary_enrollee_two_dependent_value: safely_retrive_value(primary_enrollee_two_dependent_value),
          primary_enrollee_many_dependent_value: safely_retrive_value(primary_enrollee_many_dependent_value),
          effective_date: safely_retrive_value(effective_date),
          expiration_date: safely_retrive_value(expiration_date),
          plan_id: safely_retrive_value(plan_id),
          rate_area_id: safely_retrive_value(rate_area_id),
          age_number: safely_retrive_value(age_number),
          tobacco: safely_retrive_value(tobacco),
          primary_enrollee: safely_retrive_value(primary_enrollee),
          primary_enrollee_one_dependent: safely_retrive_value(primary_enrollee_one_dependent),
          primary_enrollee_two_dependent: safely_retrive_value(primary_enrollee_two_dependent),
          primary_enrollee_many_dependent: safely_retrive_value(primary_enrollee_many_dependent),
          is_issuer_data: safely_retrive_value(is_issuer_data),
          primary_enrollee_tobacco: safely_retrive_value(primary_enrollee_tobacco),
          primary_enrollee_tobacco_value: safely_retrive_value(primary_enrollee_tobacco_value)
        }.merge(couple_hash)
      end

      def couple_hash
        {
          couple_enrollee_value: safely_retrive_value(couple_enrollee_value),
          couple_enrollee_one_dependent_value: safely_retrive_value(couple_enrollee_one_dependent_value),
          couple_enrollee_two_dependent_value: safely_retrive_value(couple_enrollee_two_dependent_value),
          couple_enrollee_many_dependent_value: safely_retrive_value(couple_enrollee_many_dependent_value),
          couple_enrollee: safely_retrive_value(couple_enrollee),
          couple_enrollee_one_dependent: safely_retrive_value(couple_enrollee_one_dependent),
          couple_enrollee_two_dependent: safely_retrive_value(couple_enrollee_two_dependent),
          couple_enrollee_many_dependent: safely_retrive_value(couple_enrollee_many_dependent)
        }
      end
    end
  end
end
