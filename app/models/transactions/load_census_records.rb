# frozen_string_literal: true

module Transactions
  # The LoadCensusRecords transaction processes employee census data from uploaded
  # spreadsheets, validates the data, and prepares it for persistence in the system.
  #
  # This transaction follows a step-by-step approach for loading, validating, and
  # transforming census records.
  class LoadCensusRecords
    include Dry::Transaction

    # Cell positions in the template for metadata
    TEMPLATE_DATE_CELL = 7
    TEMPLATE_VERSION_CELL = 13

    # Transaction steps
    step :load_file_info
    step :validate_file_info
    step :load_file_data
    step :validate_census_records
    step :parse_json_output

    private

    # Loads basic file information and metadata from the spreadsheet
    # @param input [ActionDispatch::Http::UploadedFile] Uploaded file
    # @return [Dry::Monads::Result] Success with metadata hash or Failure with error
    def load_file_info(input)
      roster = Roo::Spreadsheet.open(input.tempfile.path)
      sheet = roster.sheet(0)
      row = sheet.row(1)
      Success(
        {
          sheet:,
          template_date: row[TEMPLATE_DATE_CELL],
          template_version: row[TEMPLATE_VERSION_CELL]
        }
      )
    end

    # Validates the file information and format
    # @param input [Hash] File metadata
    # @return [Dry::Monads::Result] Success with input or Failure with validation errors
    def validate_file_info(input)
      validator = ::Validations::FileValidator.new
      result = validator.call(input)
      if result.success?
        Success(input)
      else
        Failure([result.errors.to_h])
      end
    end

    # Loads and parses the census data from the spreadsheet
    # @param input [Hash] File metadata including sheet
    # @return [Dry::Monads::Result] Success with parsed data array or Failure with error
    def load_file_data(input)
      sheet = input[:sheet]
      columns = sheet.row(2)
      output = (4..sheet.last_row).each_with_object([]) do |id, result|
        row = [columns, sheet.row(id)].transpose.to_h

        result << {
          employer_assigned_family_id: parse_text(row['employer_assigned_family_id']),
          employee_relationship: parse_relationship(row['employee_relationship']),
          last_name: parse_text(row['last_name']),
          first_name: parse_text(row['first_name']),
          dob: parse_date(row['dob'])
        }
      end
      Success(output)
    end

    # Validates each census record
    # @param input [Array] Array of census record hashes
    # @return [Dry::Monads::Result] Success with input or Failure with validation errors
    def validate_census_records(input)
      validator = ::Validations::CensusRecordValidator.new
      errors = []
      input.each_with_index do |info, _i|
        result = validator.call(info)
        errors << result.errors.to_h unless result.success?
      end
      return Failure(errors) if errors.present?

      Success(input)
    end

    # Processes census records into JSON output format
    # @param input [Array] Array of validated census record hashes
    # @return [Dry::Monads::Result] Success with JSON output or Failure with error
    def parse_json_output(input)
      output_json = {}
      input.each_with_index do |json, i|
        @index = i
        jsoned_record = insert_into_queqe(json)
        output_json[jsoned_record[:id]] = jsoned_record
      end
      Success(output_json)
    end

    # Adds a census record to the appropriate processing queue
    # @param json [Hash] Census record data
    # @return [Hash] Processed record with ID and structure
    def insert_into_queqe(json)
      if json[:employee_relationship] == 'self'
        insert_primary(json)
      else
        insert_dependent(json)
      end
    end

    # Processes a primary census record (employee)
    # @param json [Hash] Census record data for primary person
    # @return [Hash] Processed employee record
    def insert_primary(json)
      @primary_record = json
      @primary_census_employee = sanitize_params(json).merge({
                                                               census_dependents: [],
                                                               id: @index
                                                             })
    end

    # Processes a dependent census record
    # @param json [Hash] Census record data for dependent
    # @return [Hash, nil] Updated employee record with dependent, or nil if no primary exists
    def insert_dependent(json)
      return nil if @primary_census_employee.nil? || @primary_record.nil?

      params = sanitize_params(json)
      @primary_census_employee[:census_dependents] << params
      @primary_census_employee
    end

    # Extracts and sanitizes needed parameters from raw data
    # @param json [Hash] Census record data
    # @return [Hash] Sanitized parameters
    def sanitize_params(json)
      json.slice(:employer_assigned_family_id, :employee_relationship, :last_name, :first_name, :employee_relationship,
                 :dob)
    end

    # Parses relationship values from the spreadsheet
    # @param cell [String] Cell value containing relationship
    # @return [String, nil] Normalized relationship value or nil if blank
    def parse_relationship(cell)
      return nil if cell.blank?
      relationships = { 'employee' => 'self', 'self' => 'self', 'spouse' => 'spouse',
                        'domestic partner' => 'domestic_partner', 'child' => 'child_under_26',
                        'disabled child' => 'disabled_child_26_and_over' }
      relationships[parse_text(cell).downcase]
    end

    # Parses text values from the spreadsheet
    # @param cell [String] Cell value
    # @return [String, nil] Sanitized text or nil if blank
    def parse_text(cell)
      cell.blank? ? nil : sanitize_value(cell)
    end

    # Parses date values from the spreadsheet
    # @param cell [String, Date] Cell value containing a date
    # @return [Date, String, nil] Parsed date, error message, or nil if blank
    def parse_date(cell)
      return nil if cell.blank?

      if cell.instance_of?(String)
        begin
          Date.strptime(sanitize_value(cell), '%m/%d/%y')
        rescue StandardError
          begin
            Date.strptime(sanitize_value(cell), '%m-%d-%Y')
          rescue StandardError
            "#{cell} Invalid Format"
          end
        end
      else
        cell
      end
    end

    # Sanitizes a value by removing control characters and trimming whitespace
    # @param value [Object] Value to sanitize
    # @return [String] Sanitized value as a string
    def sanitize_value(value)
      value = value.to_s.split('.')[0] if value is_a? Float
      value.gsub(/[[:cntrl:]]|^\p{Space}+|\p{Space}+$/, '')
    end
  end
end
