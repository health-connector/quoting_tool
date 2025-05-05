# frozen_string_literal: true

module Services
  # The RosterUploadService handles the processing of employee roster spreadsheets,
  # allowing employers to bulk upload their employee census data.
  #
  # This service extracts employee and dependent information from standardized
  # Excel templates and converts it to the application's data format.
  class RosterUploadService
    include ActiveModel::Validations

    attr_accessor :file, :profile, :sheet, :index

    # Cell positions in the template for metadata
    TEMPLATE_DATE_CELL = 7
    TEMPLATE_VERSION_CELL = 13

    # List of fields expected in the census member record
    CENSUS_MEMBER_RECORD = %w[
      employer_assigned_family_id
      employee_relationship
      last_name
      first_name
      middle_name
      name_sfx
      email
      ssn
      dob
      gender
      hire_date
      termination_date
      is_business_owner
      benefit_group
      plan_year
      kind
      address_1
      address_2
      city
      state
      zip
      newly_designated
    ].freeze

    # Structure to hold employee and termination date
    EmployeeTerminationMap = Struct.new(:employee, :employment_terminated_on)
    # Structure to hold employee record
    EmployeePersistMap = Struct.new(:employee)

    # Initialize the service with the uploaded file
    # @param args [Hash] Hash containing the file
    def initialize(args = {})
      @file = args[:file]
    end

    # Loads metadata from the spreadsheet into the form
    # @param form [Object] Form object to load metadata into
    # @return [Object] Updated form with metadata
    def load_form_metadata(form)
      roster = Roo::Spreadsheet.open(file.tempfile.path)
      @sheet = roster.sheet(0)
      row = sheet.row(1)
      form.file = file
      form.sheet = sheet
      form.template_date = row[TEMPLATE_DATE_CELL]
      form.template_version = row[TEMPLATE_VERSION_CELL]
      form.census_titles = CENSUS_MEMBER_RECORD
      form.census_records = load_census_records_form
      form
    end

    # Loads census records from the spreadsheet
    # @return [Array] Array of CensusRecordForm objects
    def load_census_records_form
      columns = sheet.row(2)
      (4..sheet.last_row).each_with_object([]) do |id, result|
        row = [columns, sheet.row(id)].transpose.to_h
        result << Forms::CensusRecordForm.new(
          employer_assigned_family_id: parse_text(row['employer_assigned_family_id']),
          employee_relationship: parse_relationship(row['employee_relationship']),
          last_name: parse_text(row['last_name']),
          first_name: parse_text(row['first_name']),
          dob: parse_date(row['dob'])
        )
      end
    end

    # Processes and saves census records to the form
    # @param form [Object] Form containing census records
    # @return [Object] Updated form with processed data
    def save(form)
      form.census_records.each_with_index do |census_form, i|
        @index = i
        jsoned_record = insert_into_persist_queqe(census_form)
        form.output_json[jsoned_record[:id]] = jsoned_record
      end
      form
    end

    # Adds a census record to the appropriate queue
    # @param form [Object] Census record form
    # @return [Hash] JSON representation of the record
    def insert_into_persist_queqe(form)
      if form.employee_relationship == 'self'
        insert_primary(form)
      else
        insert_dependent(form)
      end
    end

    # Processes a primary census record (employee)
    # @param form [Object] Census record form for primary person
    # @return [Hash] JSON representation of the employee record
    def insert_primary(form)
      @primary_census_employee = sanitize_params(form).merge({
                                                               census_dependents: [],
                                                               id: @index
                                                             })
      @primary_record = form
      @primary_census_employee
    end

    # Processes a dependent census record
    # @param form [Object] Census record form for dependent
    # @return [Hash, nil] JSON representation of the employee record with dependent, or nil if no primary exists
    def insert_dependent(form)
      return nil if @primary_census_employee.nil? || @primary_record.nil?

      params = sanitize_params(form)
      @primary_census_employee[:census_dependents] << params
      @primary_census_employee
    end

    # Sanitizes form parameters for persistence
    # @param form [Object] Census record form
    # @return [Hash] Sanitized attributes
    def sanitize_params(form)
      form.attributes.slice(:employer_assigned_family_id, :employee_relationship, :last_name, :first_name,
                            :employee_relationship).merge({ dob: form.dob })
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
      value = value.to_s.split('.')[0] if value.is_a? Float
      value.gsub(/[[:cntrl:]]|^\p{Space}+|\p{Space}+$/, '')
    end
  end
end
