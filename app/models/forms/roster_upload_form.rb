# frozen_string_literal: true

module Forms
  # The RosterUploadForm handles the processing and validation of employee census roster spreadsheets.
  # It validates the template format, parses the file, and processes the census data.
  class RosterUploadForm
    include ActiveModel::Validations
    include Virtus.model

    # Template specifications
    TEMPLATE_DATE = Date.new(2016, 10, 26)
    TEMPLATE_VERSION = '1.1'

    attribute :template_version
    attribute :template_date
    attribute :file
    attribute :sheet
    attribute :census_records, [Forms::CensusRecordForm]
    attribute :census_titles, Array
    attribute :output_json, Hash

    validates :file, :template_version, :template_date, presence: true

    validate :roster_records
    validate :roster_template

    # Factory method to create a new form instance from a file
    # @param file [File] The uploaded roster file
    # @return [RosterUploadForm] Initialized form with metadata
    def self.call(file)
      service = resolve_service.new(file:)
      form = new
      service.load_form_metadata(form)
      form
    end

    # Returns the service class to use for roster processing
    # @return [Class] The roster upload service class
    def self.resolve_service
      Services::RosterUploadService
    end

    # Save the form data
    # @return [Boolean] Success or failure of the save operation
    def save
      persist!
    end

    # Persists the form data if valid
    # @return [Boolean] Success or failure of the persist operation
    def persist!
      return unless valid?

      service.save(self)
    end

    # Returns an instance of the roster upload service
    # @return [Services::RosterUploadService] The service instance
    def service
      @service ||= self.class.resolve_service.new
    end

    # Validates the roster template format
    # @return [Boolean] Whether the template is valid
    def roster_template
      template_date = parse_date(self.template_date)
      return if template_date == TEMPLATE_DATE && template_version == TEMPLATE_VERSION && header_valid?(sheet.row(2))

      errors.add(:base, 'Unrecognized Employee Census spreadsheet format. Contact Admin for current template.')
    end

    # Validates each census record
    # @return [void]
    def roster_records
      census_records.each_with_index do |census_record, i|
        errors.add(:base, "Row #{i + 4}: #{census_record.errors.full_messages}") unless census_record.valid?
      end
    end

    # Checks if the header row is valid
    # @param row [Array] The header row from the spreadsheet
    # @return [Boolean] Whether the header is valid
    def header_valid?(row)
      clean_header = row.reduce([]) { |memo, header_text| memo << sanitize_value(header_text) }
      clean_header == census_titles || clean_header == census_titles[0..-2]
    end

    # Parses a date string into a Date object
    # @param date [String, Date] The date to parse
    # @return [Date] The parsed date
    def parse_date(date)
      if date.is_a? Date
        date
      else
        Date.strptime(date, '%m/%d/%y')
      end
    end

    # Sanitizes a cell value
    # @param value [Object] The value to sanitize
    # @return [String] The sanitized value
    def sanitize_value(value)
      value = value.to_s.split('.')[0] if value.is_a? Float
      value.gsub(/[[:cntrl:]]|^\p{Space}+|\p{Space}+$/, '')
    end
  end
end
