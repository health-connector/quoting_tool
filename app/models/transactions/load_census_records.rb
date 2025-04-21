# frozen_string_literal: true

module Transactions
  class LoadCensusRecords
    include Dry::Transaction

    TEMPLATE_DATE_CELL = 7
    TEMPLATE_VERSION_CELL = 13

    step :load_file_info
    step :validate_file_info
    step :load_file_data
    step :validate_census_records
    step :parse_json_output

    private

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

    def validate_file_info(input)
      validator = ::Validations::FileValidator.new
      result = validator.call(input)
      if result.success?
        Success(input)
      else
        Failure([result.errors.to_h])
      end
    end

    def load_file_data(input)
      sheet = input[:sheet]
      columns = sheet.row(2)
      output = (4..sheet.last_row).each_with_object([]) do |id, result|
        row = Hash[[columns, sheet.row(id)].transpose]

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

    def parse_json_output(input)
      output_json = {}
      input.each_with_index do |json, i|
        @index = i
        jsoned_record = insert_into_queqe(json)
        output_json[jsoned_record[:id]] = jsoned_record
      end
      Success(output_json)
    end

    def insert_into_queqe(json)
      if json[:employee_relationship] == 'self'
        insert_primary(json)
      else
        insert_dependent(json)
      end
    end

    def insert_primary(json)
      @primary_record = json
      @primary_census_employee = sanitize_params(json).merge({
                                                               census_dependents: [],
                                                               id: @index
                                                             })
    end

    def insert_dependent(json)
      return nil if @primary_census_employee.nil? || @primary_record.nil?

      params = sanitize_params(json)
      @primary_census_employee[:census_dependents] << params
      @primary_census_employee
    end

    def sanitize_params(json)
      json.slice(:employer_assigned_family_id, :employee_relationship, :last_name, :first_name, :employee_relationship,
                 :dob)
    end

    def parse_relationship(cell)
      return nil if cell.blank?

      case parse_text(cell).downcase
      when 'employee'
        'self'
      when 'self'
        'self'
      when 'spouse'
        'spouse'
      when 'domestic partner'
        'domestic_partner'
      when 'child'
        'child_under_26'
      when 'disabled child'
        'disabled_child_26_and_over'
      end
    end

    def parse_text(cell)
      cell.blank? ? nil : sanitize_value(cell)
    end

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

    def sanitize_value(value)
      value = value.to_s.split('.')[0] if value.is_a? Float
      value.gsub(/[[:cntrl:]]|^\p{Space}+|\p{Space}+$/, '')
    end
  end
end
