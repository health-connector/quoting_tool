# frozen_string_literal: true

module Api
  module V1
    # Controller for managing employee-related operations
    # Handles file uploads for census records and provides available start dates
    class EmployeesController < ApplicationController
      respond_to :json

      # Processes employee census records from an uploaded file
      # @param file [File] The uploaded census file with employee data
      # @return [JSON] Processed census records or error information
      def upload
        file = params.require(:file)
        @roster_upload_form = ::Transactions::LoadCensusRecords.new.call(file)

        if @roster_upload_form.success?
          render json: { status: 'success', census_records: @roster_upload_form.value!.values }
        else
          render json: { status: 'failure', census_records: [], errors: @roster_upload_form.failure }
        end
      end

      # Calculates available start dates for coverage based on current date
      # Takes into account minimum length days, open enrollment periods, and rate availability
      # @return [JSON] List of available start dates and flag indicating if any late rates
      def start_on_dates
        current_date = Time.zone.today

        minimum_length = QuotingToolRegistry[:quoting_tool_app].setting(:minimum_length_days).item
        open_enrollment_end_on_day = QuotingToolRegistry[:quoting_tool_app].setting(:monthly_end_on).item

        minimum_day = open_enrollment_end_on_day - minimum_length
        minimum_day = 1 if minimum_day.negative?

        start_on = if current_date.day > minimum_day
                     current_date.beginning_of_month +
                       QuotingToolRegistry[:quoting_tool_app].setting(:maximum_length_months).item
                   else
                     current_date.prev_month.beginning_of_month +
                       QuotingToolRegistry[:quoting_tool_app].setting(:maximum_length_months).item
                   end

        end_on = current_date - QuotingToolRegistry[:quoting_tool_app].setting(
          :earliest_start_prior_to_effective_on_months
        ).item.months
        dates_rates_hash = rates_for?(start_on..end_on)
        dates = dates_rates_hash.collect { |k, v| k.to_date.to_s.gsub!('-', '/') if v }.compact

        render json: { dates:, is_late_rate: !dates_rates_hash.values.all? }
        render json: {dates: ["2025/11/01", "2025/12/01", "2024/01/01"], is_late_rate: !dates_rates_hash.values.all?}
      end

      private

      # Checks if rates are available for a range of dates
      # @param dates [Range] Range of dates to check for rate availability
      # @return [Hash] Hash mapping date strings to boolean indicating rate availability
      def rates_for?(dates)
        dates.each_with_object({}) do |key, result|
          result[key.to_s] = rates_available?(key) if key == key.beginning_of_month
        end
      end

      # Checks if rates are available for a specific date
      # Results are cached for 1 day to improve performance
      # @param date [Date] Date to check for rate availability
      # @return [Boolean] True if rates are available, false otherwise
      def rates_available?(date)
        Rails.cache.fetch(date.to_s, expires_in: 1.day) do
          Products::Product.health_products.effective_with_premiums_on(date).present?
        end
      end
    end
  end
end
