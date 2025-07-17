# frozen_string_literal: true

module Transactions
  # Handles loading service area data from a spreadsheet.
  # Creates or updates service area records in the database with associated counties and zip codes.
  #
  # Service areas define where insurance carriers offer their products.
  class LoadServiceAreas
    include Dry::Transaction

    step :load_file_info
    step :validate_file_info
    step :load_file_data
    step :validate_records
    step :create_records

    private

    # Opens the spreadsheet file and extracts year information from the filepath
    #
    # @param input [String] Path to the spreadsheet file
    # @return [Dry::Monads::Result::Success] Hash containing the sheet and year
    def load_file_info(input)
      year = input.split('/')[-2].to_i
      file = Roo::Spreadsheet.open(input)
      sheet = file.sheet(0)
      Success({ sheet:, year: })
    end

    # Validates the file information to ensure it meets requirements
    # Currently a placeholder for future validation implementation
    #
    # @param input [Hash] Contains the sheet and year from the previous step
    # @return [Dry::Monads::Result::Success] Same input passed through
    def validate_file_info(input)
      # validate here by adding new Validator
      Success(input)
    end

    # Extracts service area data from the spreadsheet
    #
    # @param input [Hash] Contains the sheet and year from previous steps
    # @return [Dry::Monads::Result::Success] Hash containing service area records and year
    def load_file_data(input)
      sheet = input[:sheet]
      year = input[:year]
      issuer_hios_id = sheet.cell(6, 2).to_i.to_s

      output = (13..sheet.last_row).each_with_object([]) do |i, result|
        result << {
          active_year: year,
          issuer_provided_code: sheet.cell(i, 1),
          covered_states: ['MA'], # get this from Settings
          issuer_hios_id:,
          issuer_provided_title: sheet.cell(i, 2),
          is_all_state: parse_boolean(sheet.cell(i, 3)),
          info_str: sheet.cell(i, 4),
          additional_zip: sheet.cell(i, 6)
        }
      end

      Success({ result: output, year: })
    end

    # Validates the extracted records before creation
    # Currently a placeholder for future validation implementation
    #
    # @param input [Hash] Contains the service area data from previous step
    # @return [Dry::Monads::Result::Success] Same input passed through
    def validate_records(input)
      # validate records here by adding new Validator
      Success(input)
    end

    # Creates or updates service area records in the database
    # Links each service area to its associated county/zip locations
    #
    # @param input [Hash] Contains the service area records and year from previous steps
    # @return [Dry::Monads::Result] Success with message or Failure with error message
    # rubocop:disable Metrics/MethodLength, Metrics/BlockLength
    def create_records(input)
      year = input[:year]
      input[:result].each do |params|
        if params[:is_all_state]
          Locations::ServiceArea.find_or_create_by!(
            active_year: year,
            issuer_provided_code: params[:issuer_provided_code],
            covered_states: params[:covered_states],
            issuer_provided_title: params[:issuer_provided_title],
            issuer_hios_id: params[:issuer_hios_id]
          )
        else

          service_area = Locations::ServiceArea.where(
            active_year: year,
            issuer_provided_code: params[:issuer_provided_code],
            covered_states: nil,
            issuer_provided_title: params[:issuer_provided_title],
            issuer_hios_id: params[:issuer_hios_id]
          ).first

          county_name, = extract_county_name_state_and_county_codes(params[:info_str])
          records = Locations::CountyZip.where({ county_name: })

          if params[:additional_zip].present?
            extracted_zips = extracted_zip_codes(params[:additional_zip]).each(&:squish!)
            records = records.where(:zip.in => extracted_zips)
          end

          location_ids = records.map(&:_id).uniq.compact

          if service_area.present?
            service_area.county_zip_ids += location_ids
            service_area.county_zip_ids = service_area.county_zip_ids.uniq
            service_area.save!
          else
            Locations::ServiceArea.create!({
                                             active_year: year,
                                             issuer_provided_code: params[:issuer_provided_code],
                                             issuer_hios_id: params[:issuer_hios_id],
                                             issuer_provided_title: params[:issuer_provided_title],
                                             county_zip_ids: location_ids
                                           })
          end
        end
      rescue StandardError => e
        Failure({ message: e.to_s })
      end
      Success({ message: "Successfully created/updated #{input[:result].size} Service Area records" })
    end
    # rubocop:enable Metrics/MethodLength, Metrics/BlockLength

    # Sanitizes text input by removing extra whitespace
    #
    # @param input [String, nil] Text to be sanitized
    # @return [String, nil] Sanitized text or nil
    def parse_text(input)
      return nil if input.nil?

      input.squish!
    end

    # Converts various boolean-like inputs to true/false values
    #
    # @param value [String, Boolean, nil] Value to parse as boolean
    # @return [Boolean, nil] Parsed boolean value or nil
    def parse_boolean(value)
      return true   if value == true   || value =~ /(true|t|yes|y|1)$/i
      return false  if value == false  || value =~ /(false|f|no|n|0)$/i

      nil
    end

    # Extracts county name, state code, and county code from a formatted string
    #
    # @param county_field [String] Formatted county information string
    # @return [Array<String, String, String>] County name, state code, and county code
    def extract_county_name_state_and_county_codes(county_field)
      county_name, state_and_county_code = county_field.split(' - ')
      [county_name, state_and_county_code[0..1], state_and_county_code[2..state_and_county_code.length]]
    rescue StandardError => e
      Rails.logger.debug county_field
      Rails.logger.debug e.inspect
      ['undefined', nil, nil]
    end

    # Extracts zip codes from a comma-separated string
    #
    # @param column [String] Comma-separated zip codes
    # @return [Array<String>] Array of zip codes
    def extracted_zip_codes(column)
      column.present? && column.split(/\s*,\s*/)
    end
  end
end
