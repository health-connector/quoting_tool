# frozen_string_literal: true

module Operations
  # The RateBuilder handles the creation and management of premium rates for insurance products.
  # It processes rate data and associates it with the appropriate products by creating
  # premium tables with age-based rate tuples.
  class RateBuilder
    include Dry::Transaction::Operation
    INVALID_PLAN_IDS = %w[78079DC0320003 78079DC0320004 78079DC0340002 78079DC0330002].freeze
    METLIFE_HIOS_IDS = %w[43849DC0090001 43849DC0080001].freeze

    attr_accessor :rate_groups, :rating_area_map

    # Processes rate data to create premium tables for products
    # @param params [Hash] Parameters containing rate groups and rating area mapping
    # @return [void]
    def call(params)
      @rating_area_map = params[:rating_area_map]
      @rate_groups = params[:rate_groups]
      @premium_table_map = Hash.new { |h, k| h[k] = {} }
      @products_map = []

      set_mappers
      reset_product_premium_tables
      build_premium_tables
    end

    # Translates age strings to numeric values
    # @param rate [Hash] Rate information with age_number key
    # @return [Integer] Numeric age value
    def assign_age(rate)
      case rate[:age_number]
      when '0-14'
        14
      when '0-20'
        20
      when '64 and over'
        64
      when '65 and over'
        65
      else
        rate[:age_number].to_i
      end
    end

    # Sets up the premium table mapping from rate data
    # @return [void]
    def set_mappers
      rate_groups.each do |rate_group|
        rate_group[:items].each do |rate|
          year = rate[:effective_date].to_date.year
          rate[:rate_area_id].split(',').each do |rating_area_name|
            rating_area = rating_area_name.squish.gsub('Rating Area ', 'R-MA00')
            rating_area_id = rating_area_map[[year, rating_area]]
            @premium_table_map[
              [rate[:plan_id],
               rating_area_id,
               rate[:effective_date].to_date..rate[:expiration_date].to_date]
            ][assign_age(rate)] = rate[:primary_enrollee]

            @products_map << "#{rate[:plan_id]},#{year}"
          end
        end
      end
    end

    # Resets premium tables for products that will be updated
    # @return [void]
    def reset_product_premium_tables
      @products_map.uniq.each do |value|
        hios_id, year = value.split(',')
        year = year.to_i
        ::Products::Product.where(
          :hios_base_id => /#{hios_id}/,
          :'application_period.min'.gte => Date.new(year, 1, 1),
          :'application_period.max'.lte => Date.new(year, 1, 1).end_of_year
        ).each do |product|
          product.premium_tables = []
          product.save
        end
      end
    end

    # Creates and associates premium tables with products
    # @return [void]
    def build_premium_tables
      @premium_table_map.each_pair do |k, v|
        product_hios_id, rating_area_id, applicable_range = k
        tuples = []
        year = applicable_range.min.year

        v.each_pair do |pt_age, pt_cost|
          tuples << ::Products::PremiumTuple.new(
            age: pt_age,
            cost: pt_cost
          )
        end

        ::Products::Product.where(
          :hios_base_id => /#{product_hios_id}/,
          :'application_period.min'.gte => Date.new(year, 1, 1),
          :'application_period.max'.lte => Date.new(year, 1, 1).end_of_year
        ).each do |product|
          product.premium_tables << ::Products::PremiumTable.new(
            effective_period: applicable_range,
            rating_area_id:,
            premium_tuples: tuples
          )
          product.premium_ages = tuples.map(&:age).minmax
          product.save!
        end
      end
    end
  end
end
