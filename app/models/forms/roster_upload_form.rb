module Forms
  class RosterUploadForm
    include ActiveModel::Validations
    include Virtus.model

    TEMPLATE_DATE = Date.new(2016, 10, 26)
    TEMPLATE_VERSION = '1.1'

    attribute :template_version
    attribute :template_date
    attribute :file
    attribute :sheet
    attribute :census_records, Array[Forms::CensusRecordForm]
    attribute :census_titles, Array
    attribute :output_json, Hash

    validates_presence_of :file, :template_version, :template_date

    validate :roster_records
    validate :roster_template

    def self.call(file)
      service = resolve_service.new(file:)
      form = new
      service.load_form_metadata(form)
      form
    end

    def self.resolve_service
      Services::RosterUploadService
    end

    def save
      persist!
    end

    def persist!
      return unless valid?

      service.save(self)
    end

    def service
      @service ||= self.class.resolve_service.new
    end

    def roster_template
      template_date = parse_date(self.template_date)
      return if template_date == TEMPLATE_DATE && template_version == TEMPLATE_VERSION && header_valid?(sheet.row(2))

      errors.add(:base, 'Unrecognized Employee Census spreadsheet format. Contact Admin for current template.')
    end

    def roster_records
      census_records.each_with_index do |census_record, i|
        errors.add(:base, "Row #{i + 4}: #{census_record.errors.full_messages}") unless census_record.valid?
      end
    end

    def header_valid?(row)
      clean_header = row.reduce([]) { |memo, header_text| memo << sanitize_value(header_text) }
      clean_header == census_titles || clean_header == census_titles[0..-2]
    end

    def parse_date(date)
      if date.is_a? Date
        date
      else
        Date.strptime(date, '%m/%d/%y')
      end
    end

    def sanitize_value(value)
      value = value.to_s.split('.')[0] if value.is_a? Float
      value.gsub(/[[:cntrl:]]|^\p{Space}+|\p{Space}+$/, '')
    end
  end
end
