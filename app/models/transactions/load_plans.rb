# frozen_string_literal: true

module Transactions
  class LoadPlans
    include Dry::Transaction

    step :load_file_info
    step :validate_file_info
    step :load_file_data
    step :validate_records
    step :create_records

    private

    def load_file_info(input, additional_files)
      Success({ files: input, additional_files: })
    end

    def validate_file_info(input)
      # validate here by adding new Validator
      Success(input)
    end

    def load_file_data(input)
      output = input[:files].inject([]) do |result, file|
        puts "processing file: #{file}"
        xml = Nokogiri::XML(File.open(file))
        product_hash = Parsers::Products::PlanBenefitTemplateParser.parse(xml.root.canonicalize,
                                                                          single: true).to_hash
        result += product_hash[:packages_list][:packages]
      end

      data = input[:additional_files].inject([]) do |result, file|
        year = file.split('/')[-2].to_i
        xlsx = Roo::Spreadsheet.open(file)

        health_sheet = xlsx.sheet("#{year}_QHP")
        health_columns = health_sheet.row(1).map(&:parameterize).map(&:underscore)

        health_data = (2..health_sheet.last_row).each_with_object([]) do |id, result|
          row = Hash[[health_columns, health_sheet.row(id)].transpose]

          result << {
            county_name: parse_text(row['county']),
            zip: parse_text(row['zip']),
            state: 'MA' # get this from settings
          }
        end

        health_sheet = xlsx.sheet("#{year}_QHP")
        health_columns = health_sheet.row(1).map(&:parameterize).map(&:underscore)

        health_data = (2..health_sheet.last_row).each_with_object([]) do |id, result|
          row = Hash[[health_columns, health_sheet.row(id)].transpose]

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
          row = Hash[[dental_columns, dental_sheet.row(id)].transpose]

          result << {
            hios_id: parse_text(row['hios_standard_component_id']),
            provider_directory_url: parse_text(row['provider_directory_url']),
            year:,
            is_standard_plan: parse_boolean(row['standard_plan']),
            network_information: parse_text(row['network_notes']),
            title: parse_text(row['plan_name'])
          }
        end

        result += [health_data, dental_data]
      end

      Success({ result: output, data: })
    end

    def validate_records(input)
      # validate records here by adding new Validator
      Success(input)
    end

    def create_records(input)
      health_data_map = {}
      dental_data_map = {}

      input[:data][0].map do |data|
        health_data_map[[data[:hios_id], data[:year]]] = data
      end

      input[:data][1].map do |data|
        dental_data_map[[data[:hios_id], data[:year]]] = data
      end

      builder = Operations::QhpBuilder.new.call({ packages: input[:result], health_data_map:,
                                                  dental_data_map:, service_area_map: })
      Success({ message: 'Plans Succesfully Created' })
    end

    def service_area_map
      @service_area_map = {}
      ::Locations::ServiceArea.all.map do |sa|
        @service_area_map[[sa.issuer_hios_id, sa.issuer_provided_code, sa.active_year]] = sa.id
      end
      @service_area_map
    end

    def parse_text(input)
      return nil if input.nil?

      input.squish!
    end

    def parse_boolean(value)
      value = parse_text(value)
      return true   if value == true   || value =~ (/(true|t|yes|y|1)$/i)
      return false  if value == false  || value =~ (/(false|f|no|n|0)$/i)

      nil
    end

    def parse_url(input)
      return nil if input.nil?
      return input if input.include?('http')

      "http://#{input}"
    end
  end
end
