# frozen_string_literal: true

module Transactions
  # Responsible for loading county and zip code data from a spreadsheet
  # and creating CountyZip records in the database.
  #
  # This transaction handles the entire ETL process from file loading to record creation.
  class LoadCountyZip
    include Dry::Transaction

    step :load_file_info
    step :validate_file_info
    step :load_file_data
    step :validate_records
    step :create_records

    private

    # Opens the spreadsheet file and extracts the relevant sheet
    #
    # @param input [String] Path to the spreadsheet file
    # @return [Dry::Monads::Result::Success] Hash containing the sheet
    def load_file_info(input)
      file = Roo::Spreadsheet.open(input)
      sheet = file.sheet('Master Zip Code List')
      Success({ sheet: })
    end

    # Validates the file information to ensure it meets requirements
    # Currently a placeholder for future validation implementation
    #
    # @param input [Hash] Contains the sheet from the previous step
    # @return [Dry::Monads::Result::Success] Same input passed through
    def validate_file_info(input)
      # validate here by adding new Validator
      Success(input)
    end

    # Extracts data from the spreadsheet and transforms it into a format
    # suitable for creating CountyZip records
    #
    # @param input [Hash] Contains the sheet from previous steps
    # @return [Dry::Monads::Result::Success] Hash containing the parsed results
    def load_file_data(input)
      sheet = input[:sheet]
      columns = sheet.row(1).map(&:parameterize).map(&:underscore)
      output = (2..sheet.last_row).each_with_object([]) do |id, result|
        row = [columns, sheet.row(id)].transpose.to_h

        result << {
          county_name: parse_text(row['county']),
          zip: parse_text(row['zip']),
          state: 'MA' # get this from settings
        }
      end
      Success({ result: output })
    end

    # Validates the extracted records before creation
    # Currently a placeholder for future validation implementation
    #
    # @param input [Hash] Contains the result array from previous step
    # @return [Dry::Monads::Result::Success] Same input passed through
    def validate_records(input)
      # validate records here by adding new Validator
      Success(input)
    end

    # Creates CountyZip records in the database from the processed data
    #
    # @param input [Hash] Contains the result array with records to create
    # @return [Dry::Monads::Result] Success with message or Failure with error message
    def create_records(input)
      input[:result].each_with_index do |json, i|
        return Failure({ message: "Failed to create County Zip record for index #{i}" }) unless Locations::CountyZip.find_or_create_by(json)
      end
      Success({ message: "Successfully created #{input[:result].size} County Zip records" })
    end

    # Sanitizes text input by removing extra whitespace
    #
    # @param input [String, nil] Text to be sanitized
    # @return [String, nil] Sanitized text or nil
    def parse_text(input)
      return nil if input.nil?

      input.to_s.squish!
    end
  end
end
