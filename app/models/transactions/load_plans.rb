# frozen_string_literal: true

module Transactions
  # Handles loading plan data from XML and XLSX files.
  # Processes both health and dental plan data and creates plan records in the database.
  #
  # This transaction combines data from multiple files to build complete plan records
  # with all necessary metadata and relationships.
  class LoadPlans
    include Dry::Transaction

    step :load_file_info
    step :validate_file_info
    step :load_file_data
    step :validate_records
    step :create_records

    private

    # Initializes the transaction with files and any additional files
    #
    # @param input [Array<String>] Paths to the main plan files
    # @param additional_files [Array<String>] Paths to supplementary plan data files
    # @return [Dry::Monads::Result::Success] Hash containing all file paths
    def load_file_info(input, additional_files)
      Success({ files: input, additional_files: })
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

    # Extracts plan data from both XML and XLSX files and combines them
    #
    # @param input [Hash] Contains file paths from previous steps
    # @return [Dry::Monads::Result::Success] Hash containing the combined plan data
    def load_file_data(input)
      output = input[:files].inject([]) do |result, file|
        Rails.logger.debug { "processing file: #{file}" }
        xml = Nokogiri::XML(File.open(file))
        product_hash = Parsers::Products::PlanBenefitTemplateParser.parse(xml.root.canonicalize,
                                                                          single: true).to_hash
        result + product_hash[:packages_list][:packages]
      end

      data = input[:additional_files].inject([]) do |result, file|
        year = file.split('/')[-2].to_i
        xlsx = Roo::Spreadsheet.open(file)

        health_sheet = xlsx.sheet("#{year}_QHP")
        health_columns = health_sheet.row(1).map(&:parameterize).map(&:underscore)

        (2..health_sheet.last_row).each_with_object([]) do |id, result|
          row = [health_columns, health_sheet.row(id)].transpose.to_h

          result << {
            county_name: parse_text(row['county']),
            zip: parse_text(row['zip']),
            state: 'MA' # get this from settings
          }
        end

        health_sheet = xlsx.sheet("#{year}_QHP")
        health_columns = health_sheet.row(1).map(&:parameterize).map(&:underscore)

        health_data = (2..health_sheet.last_row).each_with_object([]) do |id, result|
          row = [health_columns, health_sheet.row(id)].transpose.to_h

          product_package_kinds = []
          product_package_kinds << :single_product if parse_boolean(row['sole_source_offering'])
          product_package_kinds << :metal_level if parse_boolean(row['horizontal_offering'])
          product_package_kinds << :single_issuer if parse_boolean(row['vertical_offerring'])

          result << ({
            hios_id: parse_text(row['hios_standard_component_id']),
            provider_directory_url: parse_text(row['provider_directory_url']),
            year:,
            rx_formulary_url: parse_url(parse_text(row['rx_formulary_url'])),
            is_standard_plan: parse_boolean(row['standard_plan']),
            network_information: parse_text(row['network_notes']),
            title: parse_text(row['plan_name']),
            product_package_kinds:
          })
        end

        dental_sheet = xlsx.sheet("#{year}_QDP")
        dental_columns = dental_sheet.row(1).map(&:parameterize).map(&:underscore)

        dental_data = (2..dental_sheet.last_row).each_with_object([]) do |id, result|
          row = [dental_columns, dental_sheet.row(id)].transpose.to_h

          result << {
            hios_id: parse_text(row['hios_standard_component_id']),
            provider_directory_url: parse_text(row['provider_directory_url']),
            year:,
            is_standard_plan: parse_boolean(row['standard_plan']),
            network_information: parse_text(row['network_notes']),
            title: parse_text(row['plan_name'])
          }
        end

        result + [health_data, dental_data]
      end

      Success({ result: output, data: })
    end

    # Validates the extracted records before creation
    # Currently a placeholder for future validation implementation
    #
    # @param input [Hash] Contains the result arrays from previous step
    # @return [Dry::Monads::Result::Success] Same input passed through
    def validate_records(input)
      # validate records here by adding new Validator
      Success(input)
    end

    # Creates plan records in the database using the QhpBuilder operation
    #
    # @param input [Hash] Contains the processed plan data from previous steps
    # @return [Dry::Monads::Result::Success] Success with completion message
    def create_records(input)
      health_data_map = {}
      dental_data_map = {}

      input[:data][0].map do |data|
        health_data_map[[data[:hios_id], data[:year]]] = data
      end

      input[:data][1].map do |data|
        dental_data_map[[data[:hios_id], data[:year]]] = data
      end

      Operations::QhpBuilder.new.call({ packages: input[:result], health_data_map:,
                                        dental_data_map:, service_area_map: })
      Success({ message: 'Plans Succesfully Created' })
    end

    # Builds a map of service areas for linking to plans
    #
    # @return [Hash] Map of service areas keyed by issuer_hios_id, code, and year
    def service_area_map
      @service_area_map = {}
      ::Locations::ServiceArea.all.map do |sa|
        @service_area_map[[sa.issuer_hios_id, sa.issuer_provided_code, sa.active_year]] = sa.id
      end
      @service_area_map
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
