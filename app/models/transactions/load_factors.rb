# frozen_string_literal: true

module Transactions
  # Handles loading various rating factors from spreadsheets
  # and creating the corresponding actuarial factor records in the database.
  #
  # Processes multiple types of rating factors:
  # - SIC code rating factors
  # - Employer group size rating factors
  # - Employer participation rate factors
  # - Composite rating tier factors
  class LoadFactors
    include Dry::Transaction

    ROW_DATA_BEGINS_ON = 3

    # Maps each rating factor type to its sheet index and maximum integer factor key
    NEW_RATING_FACTOR_PAGES = {
      SicCodeRatingFactorSet: { page: 0, max_integer_factor_key: nil },
      EmployerGroupSizeRatingFactorSet: { page: 1, max_integer_factor_key: 50 },
      EmployerParticipationRateRatingFactorSet: { page: 2, max_integer_factor_key: nil },
      CompositeRatingTierFactorSet: { page: 3, max_integer_factor_key: nil }
    }.freeze
    RATING_FACTOR_DEFAULT = 1.0

    # Maps composite tier names from the spreadsheet to system values
    COMPOSITE_TIER_TRANSLATIONS = {
      Employee: 'employee_only',
      'Employee + Spouse': 'employee_and_spouse',
      'Employee + Dependent(s)': 'employee_and_one_or_more_dependents',
      Family: 'family'
    }.with_indifferent_access

    step :load_file_info
    step :validate_file_info
    step :load_file_data
    step :validate_records
    step :create_records

    private

    # Opens the spreadsheet file and extracts year information from the filepath
    #
    # @param input [String] Path to the spreadsheet file
    # @return [Dry::Monads::Result::Success] Hash containing the file and year
    def load_file_info(input)
      year = input.split('/')[-2].to_i
      file = Roo::Spreadsheet.open(input)
      Success({ file:, year: })
    end

    # Validates the file information to ensure it meets requirements
    # Currently a placeholder for future validation implementation
    #
    # @param input [Hash] Contains the file and year from the previous step
    # @return [Dry::Monads::Result::Success] Same input passed through
    def validate_file_info(input)
      # validate here by adding new Validator
      Success(input)
    end

    # Extracts rating factor data from the spreadsheet for all factor types
    #
    # @param input [Hash] Contains the file and year from previous steps
    # @return [Dry::Monads::Result::Success] Hash containing the results and year
    # rubocop:disable Metrics/MethodLength, Lint/ShadowingOuterLocalVariable
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
    # rubocop:enable Metrics/MethodLength, Lint/ShadowingOuterLocalVariable

    # Validates the extracted records before creation
    # Currently a placeholder for future validation implementation
    #
    # @param input [Hash] Contains the result array from previous step
    # @return [Dry::Monads::Result::Success] Same input passed through
    def validate_records(input)
      # validate records here by adding new Validator
      Success(input)
    end

    # Creates actuarial factor records in the database for each factor type
    #
    # @param input [Hash] Contains the results and year from previous steps
    # @return [Dry::Monads::Result::Success] Success with completion message
    def create_records(input)
      input[:year]

      NEW_RATING_FACTOR_PAGES.each do |rating_factor_class, sheet_info|
        result_ary = input[:result][sheet_info[:page]]

        object_class = resolve_rating_factor_class(rating_factor_class)

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

    def resolve_rating_factor_class(rating_factor_class)
      classes = {
        :SicCodeRatingFactorSet => ::Products::ActuarialFactors::SicActuarialFactor,
        :EmployerGroupSizeRatingFactorSet => ::Products::ActuarialFactors::GroupSizeActuarialFactor,
        :EmployerParticipationRateRatingFactorSet => ::Products::ActuarialFactors::ParticipationRateActuarialFactor,
        :CompositeRatingTierFactorSet => ::Products::ActuarialFactors::CompositeRatingTierActuarialFactor
      }
      classes[rating_factor_class]
    end

    # Returns the maximum column index for carriers in the spreadsheet
    #
    # @return [Integer] Column index
    def carrier_end_column
      13
    end

    # Checks if the rating factor class is for employer group size
    #
    # @param klass [Symbol] Rating factor class name
    # @return [Boolean] True if it's a group size rating factor
    def group_size_rating_tier?(klass)
      'EmployerGroupSizeRatingFactorSet'.eql? klass.to_s
    end

    # Checks if the rating factor class is for composite rating tier
    #
    # @param klass [Symbol] Rating factor class name
    # @return [Boolean] True if it's a composite rating factor
    def composite_rating_tier?(klass)
      'CompositeRatingTierFactorSet'.eql? klass.to_s
    end

    # Checks if the rating factor class is for participation rate
    #
    # @param klass [Symbol] Rating factor class name
    # @return [Boolean] True if it's a participation rate factor
    def participation_rate_rating_tier?(klass)
      'EmployerParticipationRateRatingFactorSet'.eql? klass.to_s
    end

    # Sanitizes text input by removing extra whitespace
    #
    # @param input [String, nil] Text to be sanitized
    # @return [String, nil] Sanitized text or nil
    def parse_text(input)
      return nil if input.nil?

      input.squish!
    end

    # Transforms the input factor key to the appropriate format based on factor type
    #
    # @param input [Object] Raw factor key value from spreadsheet
    # @param klass [Symbol] Rating factor class name
    # @return [String, Integer] Properly formatted factor key
    def get_factory_key(input, klass)
      return COMPOSITE_TIER_TRANSLATIONS[input.to_s] if composite_rating_tier?(klass)

      return input.to_i if group_size_rating_tier?(klass)

      return (input * 100).to_i if participation_rate_rating_tier?(klass)

      input
    end
  end
end
