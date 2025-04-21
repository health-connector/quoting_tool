class Api::V1::EmployeesController < ApplicationController
  respond_to :json

  def upload
    file = params.require(:file)
    @roster_upload_form = ::Transactions::LoadCensusRecords.new.call(file)

    if @roster_upload_form.success?
      render json: { status: 'success', census_records: @roster_upload_form.value!.values }
    else
      render json: { status: 'failure', census_records: [], errors: @roster_upload_form.failure }
    end
  end

  def start_on_dates
    current_date = Date.today

    minimum_length = QuotingToolRegistry[:quoting_tool_app].setting(:minimum_length_days).item
    open_enrollment_end_on_day = QuotingToolRegistry[:quoting_tool_app].setting(:monthly_end_on).item

    minimum_day = open_enrollment_end_on_day - minimum_length
    minimum_day.positive? ? minimum_day : 1

    start_on = if current_date.day > minimum_day
                 current_date.beginning_of_month + QuotingToolRegistry[:quoting_tool_app].setting(:maximum_length_months).item
               else
                 current_date.prev_month.beginning_of_month + QuotingToolRegistry[:quoting_tool_app].setting(:maximum_length_months).item
               end

    end_on = current_date - QuotingToolRegistry[:quoting_tool_app].setting(:earliest_start_prior_to_effective_on_months).item.months
    dates_rates_hash = has_rates_for(start_on..end_on)
    dates = dates_rates_hash.collect { |k, v| k.to_date.to_s.gsub!('-', '/') if v }.compact

    render json: { dates:, is_late_rate: !dates_rates_hash.values.all? }
  end

  private

  def has_rates_for(dates)
    dates.each_with_object({}) do |key, result|
      result[key.to_s] = rates_available?(key) if key == key.beginning_of_month
    end
  end

  def rates_available?(date)
    Rails.cache.fetch(date.to_s, expires_in: 1.days) do
      Products::Product.health_products.effective_with_premiums_on(date).present?
    end
  end
end
