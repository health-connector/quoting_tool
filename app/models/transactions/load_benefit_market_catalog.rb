# frozen_string_literal: true

module Transactions
  # The LoadBenefitMarketCatalog transaction orchestrates the loading of all data
  # required for a benefit market catalog, including geographic data, rating factors,
  # products, and rates.
  #
  # This transaction follows a step-by-step approach to ensure all dependencies
  # are loaded in the proper order.
  class LoadBenefitMarketCatalog
    include Dry::Transaction

    # Transaction steps
    step :load_county_zips
    step :load_rating_areas
    step :load_rating_factors
    step :load_service_areas
    step :load_plans
    step :load_rates

    private

    # Loads county zip data from template files
    # @param input [Hash] Input hash containing state code
    # @return [Dry::Monads::Result] Success with input or Failure with error
    def load_county_zips(input)
      Rails.logger.debug ':: Loading County Zip records ::'
      files = Dir.glob(Rails.root.join("db/seedfiles/plan_xmls/#{input[:state]}/xls_templates/counties", '**',
                                       '*.xlsx').to_s)
      parsed_files = parse_files(files)
      parsed_files.each do |file|
        Transactions::LoadCountyZip.new.call(file)
      end
      Rails.logger.debug ':: Finished Loading County Zip records ::'
      Success(input)
    end

    # Loads rating area data from template files
    # @param input [Hash] Input hash containing state code
    # @return [Dry::Monads::Result] Success with input or Failure with error
    def load_rating_areas(input)
      Rails.logger.debug ':: Loading Rating Area records ::'
      files = Dir.glob(Rails.root.join("db/seedfiles/plan_xmls/#{input[:state]}/xls_templates/rating_areas",
                                       '**', '*.xlsx').to_s)
      parsed_files = parse_files(files)
      parsed_files.each do |file|
        Transactions::LoadRatingAreas.new.call(file)
      end
      Rails.logger.debug ':: Finished Loading Rating Area records ::'
      Success(input)
    end

    # Loads rating factor data from template files
    # @param input [Hash] Input hash containing state code
    # @return [Dry::Monads::Result] Success with input or Failure with error
    def load_rating_factors(input)
      Rails.logger.debug ':: Loading County Rating Factor ::'
      files = Dir.glob(Rails.root.join("db/seedfiles/plan_xmls/#{input[:state]}/xls_templates/rating_factors",
                                       '**', '*.xlsx').to_s)
      parsed_files = parse_files(files)
      parsed_files.each do |file|
        Transactions::LoadFactors.new.call(file)
      end
      Rails.logger.debug ':: Finished Loading Rating Factor records ::'
      Success(input)
    end

    # Loads service area data from template files
    # @param input [Hash] Input hash containing state code
    # @return [Dry::Monads::Result] Success with input or Failure with error
    def load_service_areas(input)
      Rails.logger.debug ':: Loading Service Areas ::'
      files = Dir.glob(Rails.root.join("db/seedfiles/plan_xmls/#{input[:state]}/xls_templates/service_areas",
                                       '**', '*.xlsx').to_s)
      parsed_files = parse_files(files)
      parsed_files.each do |file|
        Transactions::LoadServiceAreas.new.call(file)
      end
      Rails.logger.debug ':: Finished Loading Service Areas ::'
      Success(input)
    end

    # Loads plan data from XML files
    # @param input [Hash] Input hash containing state code
    # @return [Dry::Monads::Result] Success with input or Failure with error
    def load_plans(input)
      Rails.logger.debug ':: Loading Plans ::'
      files = Dir.glob(Rails.root.join('db/seedfiles/plan_xmls', input[:state], 'plans', '**', '*.xml').to_s)
      parse_files(files)
      additional_files = Dir.glob(Rails.root.join("db/seedfiles/plan_xmls/#{input[:state]}/master_xml", '**',
                                                  '*.xlsx').to_s)

      parsed_files = parse_files(files)
      parsed_additional_files = parse_files(additional_files)

      transaction = Transactions::LoadPlans.new
      transaction.with_step_args(
        load_file_info: [parsed_additional_files]
      ).call(parsed_files)
      Rails.logger.debug ':: Finished Loading Plans ::'
      Success(input)
    end

    # Loads rate data from XML files
    # @param input [Hash] Input hash containing state code
    # @return [Dry::Monads::Result] Success with input or Failure with error
    def load_rates(input)
      Rails.logger.debug ':: Loading Rates ::'
      files = Dir.glob(Rails.root.join('db/seedfiles/plan_xmls', input[:state], 'rates', '**', '*.xml').to_s)
      parsed_files = parse_files(files)
      Transactions::LoadRates.new.call(parsed_files)
      Rails.logger.debug ':: Finished Loading Rates ::'
      Success(input)
    end

    # Cleans up file paths by removing temporary files and duplicates
    # @param files [Array<String>] Array of file paths
    # @return [Array<String>] Cleaned array of file paths
    def parse_files(files)
      files.map { |f| f.gsub!('~$', '') || f }.uniq
    end
  end
end
