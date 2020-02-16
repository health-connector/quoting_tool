class Api::V1::ProductsController < ApplicationController
  respond_to :json

  def plans
    effective_date = params[:start_date].to_date
    year = effective_date.year
    month = effective_date.month
    kind = params[:kind].to_sym

    county = params[:county_name].squish!
    zip = params[:zip_code].squish!
    sic = params[:sic_code]

    # data = Rails.cache.fetch("data_#{kind}_#{county}_#{zip}_#{sic}_#{year}_#{month}", expires_in: 45.minutes) do
      products = Products::Product.where(:"kind" => kind, :"service_area_id".in => service_area_ids(county, zip, year), :"application_period.min".lte => effective_date, :"application_period.max".gte => Date.new(year, 1, 1).end_of_year)
      data = products.inject([]) do |result, product|
        result << ::ProductSerializer.new(product, params: {key: sic, rating_area_id: rating_area_id(county, zip, year), quarter: quarter(month)}).serializable_hash[:data][:attributes]
        result
      end
    # end
    render :json => {status: "success", plans: data}
  end

  def sbc_document
    result = Transactions::SbcDocument.new.call({key: params[:key]})

    if result.success?
      render :json => {status: "success", metadata: result.value!.values}
    else
      render :json => {status: "failure", metadata: ''}
    end
  end

  private

  def county_zips(county, zip)
    @county_zips ||= Rails.cache.fetch("county_zips_#{county}_#{zip}", expires_in: 45.minutes) do
      ::Locations::CountyZip.all.where(county_name: county, zip: zip).map(&:id).uniq
    end
  end

  def rating_area_id(county, zip, year)
    @rating_area_id ||= Rails.cache.fetch("rating_area_id_#{county}_#{zip}_#{year}", expires_in: 45.minutes) do
      ::Locations::RatingArea.where(
        "active_year" => year,
        "county_zip_ids" => { "$in" => county_zips(county, zip) }
      ).first.id
    end
  end

  def service_area_ids(county, zip, year)
    @service_area_ids ||= Rails.cache.fetch("service_area_ids_#{county}_#{zip}_#{year}", expires_in: 45.minutes) do
      ::Locations::ServiceArea.where(
        "active_year" => year,
        "$or" => [
          {"county_zip_ids" => { "$in" => county_zips(county, zip) }},
          {"covered_states" =>  "MA"} # get this from settings
        ]
      ).map(&:id)
    end
  end

  def quarter(val)
    (val / 3.0).ceil
  end
end
