# frozen_string_literal: true

module Transactions
  class LoadFactors
    include Dry::Transaction

    ROW_DATA_BEGINS_ON ||= 3

    NEW_RATING_FACTOR_PAGES ||= {
      'SicCodeRatingFactorSet': { page: 0, max_integer_factor_key: nil },
      'EmployerGroupSizeRatingFactorSet': { page: 1, max_integer_factor_key: 50 },
      'EmployerParticipationRateRatingFactorSet': { page: 2, max_integer_factor_key: nil },
      'CompositeRatingTierFactorSet': { page: 3, max_integer_factor_key: nil }
    }.freeze
    RATING_FACTOR_DEFAULT ||= 1.0

    COMPOSITE_TIER_TRANSLATIONS ||= {
      'Employee': 'employee_only',
      'Employee + Spouse': 'employee_and_spouse',
      'Employee + Dependent(s)': 'employee_and_one_or_more_dependents',
      'Family': 'family'
    }.with_indifferent_access

    step :load_file_info
    step :validate_file_info
    step :load_file_data
    step :validate_records
    step :create_records

    private

    def load_file_info(input)
      year = input.split('/')[-2].to_i
      file = Roo::Spreadsheet.open(input)
      Success({ file:, year: })
    end

    def validate_file_info(input)
      # validate here by adding new Validator
      Success(input)
    end

    def load_file_data(input)
      file = input[:file]
      year = input[:year]

      output = NEW_RATING_FACTOR_PAGES.each_with_object([]) do |info, result|
        rating_factor_class = info[0]
        sheet_info = info[1]
        sheet = file.sheet(sheet_info[:page])
        max_integer_factor_key = sheet_info[:max_integer_factor_key]

        result << (2..carrier_end_column).each_with_object([]) do |carrier_column, result|
          issuer_hios_id = sheet.cell(2, carrier_column).to_i

          next unless issuer_hios_id.positive? # Making sure it's hios-id

          factors = (ROW_DATA_BEGINS_ON..sheet.last_row).each_with_object([]) do |i, result|
            factor_key = get_factory_key(sheet.cell(i, 1), rating_factor_class)

            factor_value = sheet.cell(i, carrier_column) || 1.0

            result << ({
              factor_key:,
              factor_value:
            })
          end

          result << ({
            active_year: year,
            default_factor_value: RATING_FACTOR_DEFAULT,
            issuer_hios_id: issuer_hios_id.to_s,
            max_integer_factor_key:,
            factors:
          })
        end
      end

      Success({ result: output, year: })
    end

    def validate_records(input)
      # validate records here by adding new Validator
      Success(input)
    end

    def create_records(input)
      input[:year]

      NEW_RATING_FACTOR_PAGES.each do |rating_factor_class, sheet_info|
        result_ary = input[:result][sheet_info[:page]]

        object_class = case rating_factor_class
                       when :SicCodeRatingFactorSet
                         ::Products::ActuarialFactors::SicActuarialFactor
                       when :EmployerGroupSizeRatingFactorSet
                         ::Products::ActuarialFactors::GroupSizeActuarialFactor
                       when :EmployerParticipationRateRatingFactorSet
                         ::Products::ActuarialFactors::ParticipationRateActuarialFactor
                       when :CompositeRatingTierFactorSet
                         ::Products::ActuarialFactors::CompositeRatingTierActuarialFactor
                       end

        result_ary.each do |json|
          record = object_class.where(
            active_year: json[:active_year],
            default_factor_value: json[:default_factor_value],
            issuer_hios_id: json[:issuer_hios_id],
            max_integer_factor_key: json[:max_integer_factor_key]
          ).first

          next if record.present?

          obj = object_class.new(
            active_year: json[:active_year],
            default_factor_value: json[:default_factor_value],
            issuer_hios_id: json[:issuer_hios_id],
            max_integer_factor_key: json[:max_integer_factor_key],
            actuarial_factor_entries: json[:factors]
          )
          obj.save!
        end
      end
      Success({ message: 'Successfully created/updated Rating Factor records' })
    end

    def carrier_end_column
      13
    end

    def is_group_size_rating_tier?(klass)
      'EmployerGroupSizeRatingFactorSet'.eql? klass.to_s
    end

    def is_composite_rating_tier?(klass)
      'CompositeRatingTierFactorSet'.eql? klass.to_s
    end

    def is_participation_rate_rating_tier?(klass)
      'EmployerParticipationRateRatingFactorSet'.eql? klass.to_s
    end

    def parse_text(input)
      return nil if input.nil?

      input.squish!
    end

    def get_factory_key(input, klass)
      return COMPOSITE_TIER_TRANSLATIONS[input.to_s] if is_composite_rating_tier?(klass)

      return input.to_i if is_group_size_rating_tier?(klass)

      return (input * 100).to_i if is_participation_rate_rating_tier?(klass)

      input
    end
  end
end
