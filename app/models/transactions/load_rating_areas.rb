# frozen_string_literal: true

module Transactions
  # Handles loading rating area data from a spreadsheet.
  # Creates or updates rating area records in the database with associated counties and zip codes.
  #
  # Rating areas are geographical regions used for insurance pricing.
  class LoadRatingAreas
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

    # Extracts rating area data from the spreadsheet and organizes it by rating area
    #
    # @param input [Hash] Contains the sheet and year from previous steps
    # @return [Dry::Monads::Result::Success] Hash containing organized rating area data
    def load_file_data(input)
      sheet = input[:sheet]
      year = input[:year]
      input[:sheet].row(1).map(&:parameterize).map(&:underscore)
      output = Hash.new { |results, k| results[k] = [] }

      (2..sheet.last_row).each do |i|
        output[sheet.cell(i, 4)] << {
          'county_name' => sheet.cell(i, 2),
          'zip' => sheet.cell(i, 1)
        }
      end

      Success({ result: output, year: })
    end

    # Validates the extracted records before creation
    # Currently a placeholder for future validation implementation
    #
    # @param input [Hash] Contains the rating area data from previous step
    # @return [Dry::Monads::Result::Success] Same input passed through
    def validate_records(input)
      # validate records here by adding new Validator
      Success(input)
    end

    # Creates or updates rating area records in the database
    # Links each rating area to its associated county/zip locations
    #
    # @param input [Hash] Contains the organized rating area data from previous steps
    # @return [Dry::Monads::Result] Success with message or Failure with error message
    def create_records(input)
      year = input[:year]
      input[:result].each do |rating_area_id, locations|
        location_ids = get_location_ids(locations)

        rating_area = Locations::RatingArea.where({
                                                    active_year: year,
                                                    exchange_provided_code: rating_area_id
                                                  }).first
        begin
          if rating_area.present?
            rating_area.county_zip_ids = location_ids
          else
            rating_area = Locations::RatingArea.new
            rating_area.active_year = year
            rating_area.exchange_provided_code = rating_area_id
            rating_area.county_zip_ids = location_ids
          end
          rating_area.save!
        rescue StandardError
          return Failure({ message: "Error Updating/Creating Rating Area record for location_ids #{location_ids}"  })
        end
      end
      Success({ message: "Successfully created/updated #{input[:result].keys.size} Rating Area records" })
    end

    def get_location_ids(locations)
      locations.map do |loc_record|
        county_zip = Locations::CountyZip.where({
                                                  zip: loc_record['zip'],
                                                  county_name: loc_record['county_name']
                                                }).first
        county_zip._id
      end
    end

    # Sanitizes text input by removing extra whitespace
    #
    # @param input [String, nil] Text to be sanitized
    # @return [String, nil] Sanitized text or nil
    def parse_text(input)
      return nil if input.nil?

      input.squish!
    end
  end
end
