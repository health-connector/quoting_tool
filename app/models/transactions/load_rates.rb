# frozen_string_literal: true

module Transactions
  # Handles loading rate data from XML files.
  # Creates rate records in the database using the RateBuilder operation.
  #
  # This transaction processes rate group data for products and creates
  # the corresponding rate records.
  class LoadRates
    include Dry::Transaction

    step :load_file_info
    step :validate_file_info
    step :load_file_data
    step :validate_records
    step :create_records

    private

    # Initializes the transaction with rate files
    #
    # @param input [Array<String>] Paths to the rate XML files
    # @return [Dry::Monads::Result::Success] Hash containing file paths
    def load_file_info(input)
      Success({ files: input })
    end

    # Validates the file information to ensure it meets requirements
    # Currently a placeholder for future validation implementation
    #
    # @param input [Hash] Contains file paths from the previous step
    # @return [Dry::Monads::Result::Success] Same input passed through
    def validate_file_info(input)
      # validate here by adding new Validator
      Success(input)
    end

    # Extracts rate data from XML files
    #
    # @param input [Hash] Contains file paths from previous steps
    # @return [Dry::Monads::Result::Success] Hash containing the parsed rate groups
    def load_file_data(input)
      output = input[:files].inject([]) do |result, file|
        xml = Nokogiri::XML(File.open(file))
        product_hash = Parsers::Products::PlanRateGroupListParser.parse(xml.root.canonicalize, single: true).to_hash
        result + product_hash[:plan_rate_group_attributes]
      end
      Success({ result: output })
    end

    # Validates the extracted records before creation
    # Currently a placeholder for future validation implementation
    #
    # @param input [Hash] Contains the rate groups from previous step
    # @return [Dry::Monads::Result::Success] Same input passed through
    def validate_records(input)
      # validate records here by adding new Validator
      Success(input)
    end

    # Creates rate records in the database using the RateBuilder operation
    #
    # @param input [Hash] Contains the processed rate data from previous steps
    # @return [Dry::Monads::Result::Success] Success with completion message
    def create_records(input)
      Operations::RateBuilder.new.call({ rate_groups: input[:result], rating_area_map: })
      Success({ message: 'Rates Succesfully Loaded' })
    end

    # Builds a map of rating areas for linking to rates
    #
    # @return [Hash] Map of rating areas keyed by year and code
    def rating_area_map
      @rating_area_map = {}
      ::Locations::RatingArea.all.map do |ra|
        @rating_area_map[[ra.active_year, ra.exchange_provided_code]] = ra.id
      end
      @rating_area_map
    end

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
      value = parse_text(value)
      return true   if value == true   || value =~ (/(true|t|yes|y|1)$/i)
      return false  if value == false  || value =~ (/(false|f|no|n|0)$/i)

      nil
    end

    # Ensures URLs include the protocol
    #
    # @param input [String, nil] URL to format
    # @return [String, nil] Formatted URL with protocol or nil
    def parse_url(input)
      return nil if input.nil?
      return input if input.include?('http')

      "http://#{input}"
    end
  end
end
