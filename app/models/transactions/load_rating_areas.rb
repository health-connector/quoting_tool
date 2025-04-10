module Transactions
  class LoadRatingAreas
    include Dry::Transaction

    step :load_file_info
    step :validate_file_info
    step :load_file_data
    step :validate_records
    step :create_records

    private


    def load_file_info(input)
      year = input.split("/")[-2].to_i
      file = Roo::Spreadsheet.open(input)
      sheet = file.sheet(0)
      Success({sheet: sheet, year: year})
    end

    def validate_file_info(input)
      # validate here by adding new Validator
      Success(input)
    end

    def load_file_data(input)
      sheet = input[:sheet]
      year = input[:year]
      columns = input[:sheet].row(1).map(&:parameterize).map(&:underscore)
      output = Hash.new {|results, k| results[k] = []}

      (2..sheet.last_row).each do |i|
        output[sheet.cell(i, 4)] << {
          "county_name" => sheet.cell(i, 2),
          "zip" => sheet.cell(i, 1)
        }
      end

      Success({result: output, year: year})
    end

    def validate_records(input)
      # validate records here by adding new Validator
      Success(input)
    end

    def create_records(input)
      year = input[:year]
      input[:result].each do |rating_area_id, locations|

        location_ids = locations.map do |loc_record|
          county_zip = Locations::CountyZip.where({
                                                    zip: loc_record['zip'],
                                                    county_name: loc_record['county_name']
                                                  }).first
          county_zip._id
        end

        rating_area = Locations::RatingArea.where({
                                                    active_year: year,
                                                    exchange_provided_code: rating_area_id,
                                                  }).first

        if rating_area.present?
          rating_area.county_zip_ids = location_ids
          begin
            rating_area.save!
          rescue => e
            return Failure({message: "Failed to Save Rating Area record for #{rating_area.id}"})
          end
        else
          rating_area = Locations::RatingArea.new
          rating_area.active_year = year
          rating_area.exchange_provided_code = rating_area_id
          rating_area.county_zip_ids = location_ids
          begin
            rating_area.save!
          rescue => e
            return Failure({message: "Error creating Rating Area record for #{rating_area_id}"})
          end
        end
      end
      Success({message: "Successfully created/updated #{input[:result].keys.size} Rating Area records"})
    end

    def parse_text(input)
      return nil if input.nil?
      input.squish!
    end
  end
end
