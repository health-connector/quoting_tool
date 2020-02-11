class Api::V1::EmployeesController < ApplicationController
  respond_to :json

  def upload
    file = params.require(:file)
    @roster_upload_form = ::Transactions::LoadCensusRecords.new.call(file)

    if @roster_upload_form.success?
      render :json => {status: "success", census_records: @roster_upload_form.value!.values}
    else
      render :json => {status: "failure", census_records: [], errors: @roster_upload_form.failure}
    end
  end

  def start_on_dates
    current_date = Date.today
    minimum_length = Registry.resolve "aca_shop_market.open_enrollment.minimum_length_days"
    open_enrollment_end_on_day = Registry.resolve "aca_shop_market.open_enrollment.monthly_end_on"

    minimum_day = open_enrollment_end_on_day - minimum_length
    minimum_day.positive? ? minimum_day : 1

    start_on =  if current_date.day > minimum_day
                  current_date.beginning_of_month + Registry.resolve("aca_shop_market.open_enrollment.maximum_length_months").months
                else
                  current_date.prev_month.beginning_of_month + Registry.resolve("aca_shop_market.open_enrollment.maximum_length_months").months
                end

    end_on = current_date - (Registry.resolve("aca_shop_market.initial_application.earliest_start_prior_to_effective_on_months").months)
    dates = (start_on..end_on).select {|t| t == t.beginning_of_month}.map {|a| a.to_s}.map{ |a| a.gsub!("-","/")}
    render json: { dates: dates }
  end
end

