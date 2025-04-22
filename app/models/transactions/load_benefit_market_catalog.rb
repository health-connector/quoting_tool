# frozen_string_literal: true

module Transactions
  class LoadBenefitMarketCatalog
    include Dry::Transaction

    step :load_county_zips
    step :load_rating_areas
    step :load_rating_factors
    step :load_service_areas
    step :load_plans
    step :load_rates

    private

    def load_county_zips(input)
      puts ':: Loading County Zip records ::'
      files = Dir.glob(Rails.root.join("db/seedfiles/plan_xmls/#{input[:state]}/xls_templates/counties", '**',
                                       '*.xlsx').to_s)
      parsed_files = parse_files(files)
      parsed_files.each do |file|
        Transactions::LoadCountyZip.new.call(file)
      end
      puts ':: Finished Loading County Zip records ::'
      Success(input)
    end

    def load_rating_areas(input)
      puts ':: Loading Rating Area records ::'
      files = Dir.glob(Rails.root.join("db/seedfiles/plan_xmls/#{input[:state]}/xls_templates/rating_areas",
                                       '**', '*.xlsx').to_s)
      parsed_files = parse_files(files)
      parsed_files.each do |file|
        Transactions::LoadRatingAreas.new.call(file)
      end
      puts ':: Finished Loading Rating Area records ::'
      Success(input)
    end

    def load_rating_factors(input)
      puts ':: Loading County Rating Factor ::'
      files = Dir.glob(Rails.root.join("db/seedfiles/plan_xmls/#{input[:state]}/xls_templates/rating_factors",
                                       '**', '*.xlsx').to_s)
      parsed_files = parse_files(files)
      parsed_files.each do |file|
        Transactions::LoadFactors.new.call(file)
      end
      puts ':: Finished Loading Rating Factor records ::'
      Success(input)
    end

    def load_service_areas(input)
      puts ':: Loading Service Areas ::'
      files = Dir.glob(Rails.root.join("db/seedfiles/plan_xmls/#{input[:state]}/xls_templates/service_areas",
                                       '**', '*.xlsx').to_s)
      parsed_files = parse_files(files)
      parsed_files.each do |file|
        Transactions::LoadServiceAreas.new.call(file)
      end
      puts ':: Finished Loading Service Areas ::'
      Success(input)
    end

    def load_plans(input)
      puts ':: Loading Plans ::'
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
      puts ':: Finished Loading Plans ::'
      Success(input)
    end

    def load_rates(input)
      puts ':: Loading Rates ::'
      files = Dir.glob(Rails.root.join('db/seedfiles/plan_xmls', input[:state], 'rates', '**', '*.xml').to_s)
      parsed_files = parse_files(files)
      Transactions::LoadRates.new.call(parsed_files)
      puts ':: Finished Loading Rates ::'
      Success(input)
    end

    def parse_files(files)
      files.map { |f| f.gsub!('~$', '') || f }.uniq
    end
  end
end
