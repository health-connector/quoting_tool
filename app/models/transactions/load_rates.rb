# frozen_string_literal: true

module Transactions
  class LoadRates
    include Dry::Transaction

    step :load_file_info
    step :validate_file_info
    step :load_file_data
    step :validate_records
    step :create_records

    private

    def load_file_info(input)
      Success({ files: input })
    end

    def validate_file_info(input)
      # validate here by adding new Validator
      Success(input)
    end

    def load_file_data(input)
      output = input[:files].inject([]) do |result, file|
        xml = Nokogiri::XML(File.open(file))
        product_hash = Parsers::Products::PlanRateGroupListParser.parse(xml.root.canonicalize, single: true).to_hash
        result + product_hash[:plan_rate_group_attributes]
      end
      Success({ result: output })
    end

    def validate_records(input)
      # validate records here by adding new Validator
      Success(input)
    end

    def create_records(input)
      Operations::RateBuilder.new.call({ rate_groups: input[:result], rating_area_map: })
      Success({ message: 'Rates Succesfully Loaded' })
    end

    def rating_area_map
      @rating_area_map = {}
      ::Locations::RatingArea.all.map do |ra|
        @rating_area_map[[ra.active_year, ra.exchange_provided_code]] = ra.id
      end
      @rating_area_map
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
