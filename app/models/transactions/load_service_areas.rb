module Transactions
  class LoadServiceAreas
    include Dry::Transaction

    step :load_file_info
    step :validate_file_info
    step :load_file_data
    step :validate_records
    step :create_records

    private

    def load_file_info(input)
      year = input.split('/')[-2].to_i
      file = Roo::Spreadsheet.open(input)
      sheet = file.sheet(0)
      Success({ sheet:, year: })
    end

    def validate_file_info(input)
      # validate here by adding new Validator
      Success(input)
    end

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

    def validate_records(input)
      # validate records here by adding new Validator
      Success(input)
    end

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

          county_name, state_code, county_code = extract_county_name_state_and_county_codes(params[:info_str])
          records = Locations::CountyZip.where({ county_name: })

          if params[:additional_zip].present?
            extracted_zips = extracted_zip_codes(params[:additional_zip]).each { |t| t.squish! }
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
      rescue Exception => e
        Failure({ message: "#{e}" })
      end
      Success({ message: "Successfully created/updated #{input[:result].size} Service Area records" })
    end

    def parse_text(input)
      return nil if input.nil?

      input.squish!
    end

    def parse_boolean(value)
      return true   if value == true   || value =~ (/(true|t|yes|y|1)$/i)
      return false  if value == false  || value =~ (/(false|f|no|n|0)$/i)

      nil
    end

    def extract_county_name_state_and_county_codes(county_field)
      county_name, state_and_county_code = county_field.split(' - ')
      [county_name, state_and_county_code[0..1], state_and_county_code[2..state_and_county_code.length]]
    rescue StandardError => e
      puts county_field
      puts e.inspect
      ['undefined', nil, nil]
    end

    def extracted_zip_codes(column)
      column.present? && column.split(/\s*,\s*/)
    end
  end
end
