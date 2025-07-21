# frozen_string_literal: true

module Api
  module V1
    # Controller for managing insurance products and plans
    # Provides endpoints for retrieving plan information and related documents
    class ProductsController < ApplicationController
      respond_to :json

      # Retrieves plans based on location and other parameters
      # @param start_date [String] Effective date for plan selection
      # @param kind [String] Type of plan (e.g., :health, :dental)
      # @param county_name [String] County name for service area determination
      # @param zip_code [String] ZIP code for service area determination
      # @param sic_code [String] Standard Industrial Classification code
      # @return [JSON] List of available plans with their details
      def plans
        effective_date = params[:start_date].to_date
        year = effective_date.year
        month = effective_date.month
        kind = params[:kind].to_sym

        county = params[:county_name].squish!
        zip = params[:zip_code].squish!
        sic = params[:sic_code]

        cache_key = "data_#{kind}_#{county}_#{zip}_#{sic}_#{year}_#{month}"
        data = Rails.cache.read(cache_key)
        if data.nil?
          data = Products::Product.where(:kind => kind,
                                         :service_area_id.in => service_area_ids(county, zip, year),
                                         :'application_period.min'.lte => effective_date,
                                         :'application_period.max'.gte => Date.new(year, 1, 1).end_of_year)
          data = data.each_with_object([]) do |product, result|
            result << ::ProductSerializer.new(product,
                                              params: { key: sic, rating_area_id: rating_area_id(county, zip, year),
                                                        quarter: quarter(month) }).serializable_hash[:data][:attributes]
          end
          Rails.cache.write(cache_key, data, expires_in: 45.minutes)
        end
        render json: { status: 'success', plans: data }
      end

      # Retrieves Summary of Benefits and Coverage (SBC) document
      # @param key [String] Identifier for the requested document
      # @return [JSON] Document metadata if found
      def sbc_document
        result = Transactions::SbcDocument.new.call({ key: params[:key] })

        if result.success?
          render json: { status: 'success', metadata: result.value!.values }
        else
          render json: { status: 'failure', metadata: '' }
        end
      end

      private

      # Gets county zip identifiers for a specific county and zip
      # @param county [String] County name
      # @param zip [String] ZIP code
      # @return [Array<String>] List of county zip identifiers
      def county_zips(county, zip)
        @county_zips ||= Rails.cache.read("county_zips_#{county}_#{zip}")
        if @county_zips.nil?
          @county_zips = ::Locations::CountyZip.where(county_name: county, zip:).map(&:id).uniq
          Rails.cache.write("county_zips_#{county}_#{zip}", @county_zips, expires_in: 45.minutes)
        end
        @county_zips
      end

      # Determines the rating area ID for a specific location and year
      # @param county [String] County name
      # @param zip [String] ZIP code
      # @param year [Integer] Year for rating area
      # @return [String] Rating area identifier
      def rating_area_id(county, zip, year)
        @rating_area_id ||= Rails.cache.read("rating_area_id_#{county}_#{zip}_#{year}")
        if @rating_area_id.nil?
          @rating_area_id = ::Locations::RatingArea.where(
            'active_year' => year,
            'county_zip_ids' => { '$in' => county_zips(county, zip) }
          ).first.id
          Rails.cache.write("rating_area_id_#{county}_#{zip}_#{year}", @rating_area_id, expires_in: 45.minutes)
        end
        @rating_area_id
      end

      # Determines the service area IDs for a specific location and year
      # @param county [String] County name
      # @param zip [String] ZIP code
      # @param year [Integer] Year for service areas
      # @return [Array<String>] List of service area identifiers
      def service_area_ids(county, zip, year)
        @service_area_ids ||= Rails.cache.read("service_area_ids_#{county}_#{zip}_#{year}")
        if @service_area_ids.nil?
          @service_area_ids = ::Locations::ServiceArea.where(
            'active_year' => year,
            '$or' => [
              { 'county_zip_ids' => { '$in' => county_zips(county, zip) } },
              { 'covered_states' => 'MA' } # get this from settings
            ]
          ).map(&:id)
          Rails.cache.write("service_area_ids_#{county}_#{zip}_#{year}", @service_area_ids, expires_in: 45.minutes)
        end
        @service_area_ids
      end

      # Calculate quarter (Q1-Q4) from a month value (1-12)
      # @param val [Integer] The month (1-12)
      # @return [Integer] The quarter (1-4)
      def quarter(val)
        (val / 3.0).ceil
      end
    end
  end
end
