module Services
  class RosterUploadService
    include ActiveModel::Validations

    attr_accessor :file, :profile, :sheet, :index

    TEMPLATE_DATE_CELL = 7
    TEMPLATE_VERSION_CELL = 13

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
    ]

    EmployeeTerminationMap = Struct.new(:employee, :employment_terminated_on)
    EmployeePersistMap = Struct.new(:employee)

    def initialize(args = {})
      @file = args[:file]
    end

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

    def load_census_records_form
      census_records = []
      columns = sheet.row(2)
      (4..sheet.last_row).each_with_object([]) do |id, result|
        row = Hash[[columns, sheet.row(id)].transpose]
        result << Forms::CensusRecordForm.new(
          employer_assigned_family_id: parse_text(row['employer_assigned_family_id']),
          employee_relationship: parse_relationship(row['employee_relationship']),
          last_name: parse_text(row['last_name']),
          first_name: parse_text(row['first_name']),
          dob: parse_date(row['dob'])
        )
      end
    end

    def save(form)
      form.census_records.each_with_index do |census_form, i|
        @index = i
        jsoned_record = insert_into_persist_queqe(census_form)
        form.output_json[jsoned_record[:id]] = jsoned_record
      end
      form
    end

    def insert_into_persist_queqe(form)
      if form.employee_relationship == 'self'
        insert_primary(form)
      else
        insert_dependent(form)
      end
    end

    def insert_primary(form)
      @primary_census_employee = sanitize_params(form).merge({
                                                               census_dependents: [],
                                                               id: @index
                                                             })
      @primary_record = form
      @primary_census_employee
    end

    def insert_dependent(form)
      return nil if @primary_census_employee.nil? || @primary_record.nil?

      params = sanitize_params(form)
      @primary_census_employee[:census_dependents] << params
      @primary_census_employee
    end

    def sanitize_params(form)
      form.attributes.slice(:employer_assigned_family_id, :employee_relationship, :last_name, :first_name,
                            :employee_relationship).merge({ dob: form.dob })
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
