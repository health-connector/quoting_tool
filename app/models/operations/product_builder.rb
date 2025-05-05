# frozen_string_literal: true

module Operations
  # The ProductBuilder handles the creation and updating of insurance product records
  # based on QHP (Qualified Health Plan) data. It processes plan information from various
  # sources and builds both health and dental product records.
  class ProductBuilder
    include Dry::Transaction::Operation
    include Dry::Monads[:result]

    # Mapping of visit types used in cost share variance data
    VISIT_TYPES = {
      pcp: 'Primary Care Visit to Treat an Injury or Illness',
      emergency_stay: 'Emergency Room Services',
      hospital_stay: 'Inpatient Hospital Services (e.g., Hospital Stay)',
      rx: 'Generic Drugs',
      basic_dental_services: 'Basic Dental Care - Adult',
      major_dental_services: 'Major Dental Care - Adult',
      preventive_dental_services: 'Routine Dental Services (Adult)'
    }.freeze

    # Mapping of tier factor names for display purposes
    TF_NAME_MAP = {
      'employee_only' => 'Employee Only',
      'employee_and_spouse' => 'Employee and Spouse',
      'employee_and_one_or_more_dependents' => 'Employee and Dependents',
      'family' => 'Family'
    }.freeze

    attr_accessor :qhp, :health_data_map, :dental_data_map

    # Builds or updates a product based on QHP data
    # @param params [Hash] Parameters containing QHP and mapping data
    # @return [Dry::Monads::Result::Success] Success object with product information
    def call(params)
      @qhp = params[:qhp]
      @health_data_map = params[:health_data_map]
      @dental_data_map = params[:dental_data_map]
      created_product = nil

      @qhp.qhp_cost_share_variances.each do |cost_share_variance|
        hios_base_id, csr_variant_id = cost_share_variance.hios_plan_and_variant_id.split('-')
        next if csr_variant_id == '00'

        csr_variant_id = '' if retrieve_metal_level == 'dental'
        product = retrieve_first_matching_product(hios_base_id, csr_variant_id, qhp)

        (params[:service_area_map][[qhp.issuer_id, qhp.service_area_id, qhp.active_year]] if params[:service_area_map].present?)

        attrs = build_product_hash(cost_share_variance, hios_base_id, health_data_map, dental_data_map)

        if product.present?
          product.issuer_hios_ids = (product.issuer_hios_ids + qhp.issuer_id).uniq
          product.update!(attrs)
          cost_share_variance.product_id = product.id if cost_share_variance.product_id.blank?
          created_product = product
        else
          new_product = create_new_product(attrs.merge({ issuer_hios_ids: [qhp.issuer_id] }))

          if new_product.save!
            cost_share_variance.product_id = new_product.id
            created_product = new_product
          end
        end
      end

      Success({ message: 'Successfully created/updated Plan records', product: created_product })
    end

    def build_product_hash(cost_share_variance, hios_base_id, health_data_map, dental_data_map)
      shared_attrs = shared_hash(cost_share_variance)

      specific_attrs = if health_product?
                         health_hash(health_data_map[[hios_base_id, qhp.active_year]], qhp, cost_share_variance)
                       else
                         dental_hash(dental_data_map[[hios_base_id, qhp.active_year]], qhp)
                       end

      shared_attrs.merge(specific_attrs)
    end

    def create_new_product(attrs)
      if health_product?
        ::Products::HealthProduct.new(attrs)
      else
        ::Products::DentalProduct.new(attrs)
      end
    end

    def retrieve_first_matching_product(hios_base_id, csr_variant_id, qhp)
      ::Products::Product.where(
        :hios_base_id => hios_base_id,
        :csr_variant_id => csr_variant_id,
        :'application_period.min'.gte => Date.new(qhp.active_year, 1, 1),
        :'application_period.max'.lte => Date.new(qhp.active_year, 1, 1).end_of_year
      ).first
    end

    def shared_hash(cost_share_variance)
      {
        benefit_market_kind: "aca_#{parse_market}",
        title: cost_share_variance.plan_marketing_name.squish,
        hios_id: health_product? ? cost_share_variance.hios_plan_and_variant_id : hios_base_id,
        hios_base_id: nil,
        csr_variant_id: nil,
        application_period: (Date.new(qhp.active_year, 1, 1)..Date.new(qhp.active_year, 12, 31)),
        service_area_id: nil,
        deductible: cost_share_variance.qhp_deductable.in_network_tier_1_individual,
        family_deductible: cost_share_variance.qhp_deductable.in_network_tier_1_family,
        is_reference_plan_eligible: true,
        metal_level_kind: retrieve_metal_level.to_sym,
        group_size_factors: group_size_factors(qhp.active_year, qhp.issuer_id),
        group_tier_factors: group_tier_factors(qhp.active_year, qhp.issuer_id),
        participation_factors: participation_factors(qhp.active_year, qhp.issuer_id),
        hsa_eligible: qhp.hsa_eligibility,
        out_of_pocket_in_network: out_of_pocket_in_network(cost_share_variance)
      }
    end

    def health_hash(info, qhp, cost_share_variance)
      {
        health_plan_kind: qhp.plan_type.downcase,
        ehb: qhp.ehb_percent_premium.presence || 1.0,
        pcp_in_network_copay: pcp_in_network_copay(cost_share_variance),
        hospital_stay_in_network_copay: hospital_stay_in_network_copay(cost_share_variance),
        emergency_in_network_copay: emergency_in_network_copay(cost_share_variance),
        drug_in_network_copay: drug_in_network_copay(cost_share_variance),
        pcp_in_network_co_insurance: service_visit_co_insurance(cost_share_variance, :pcp),
        hospital_stay_in_network_co_insurance: service_visit_co_insurance(cost_share_variance, :hospital_stay),
        emergency_in_network_co_insurance: service_visit_co_insurance(cost_share_variance, :emergency_stay),
        drug_in_network_co_insurance: service_visit_co_insurance(cost_share_variance, :rx),
        is_standard_plan: info[:is_standard_plan],
        network_information: info[:network_information],
        title: info[:title] || cost_share_variance.plan_marketing_name.squish!,
        product_package_kinds: info[:product_package_kinds],
        rx_formulary_url: info[:rx_formulary_url],
        provider_directory_url: info[:provider_directory_url]
      }
    end

    def dental_hash(info, qhp)
      {
        dental_plan_kind: qhp.plan_type.downcase,
        dental_level: qhp.metal_level.downcase,
        product_package_kinds: ::Products::DentalProduct::PRODUCT_PACKAGE_KINDS,
        is_standard_plan: info[:is_standard_plan],
        network_information: info[:network_information],
        title: info[:title] || cost_share_variance.plan_marketing_name.squish!,
        provider_directory_url: info[:provider_directory_url],
        basic_dental_services: basic_dental_services(cost_share_variance),
        major_dental_services: major_dental_services(cost_share_variance),
        preventive_dental_services: preventive_dental_services(cost_share_variance)
      }
    end

    # Retrieves group size factors for a given year and issuer
    # @param year [Integer] The year for which to retrieve factors
    # @param hios_id [String] The HIOS ID of the issuer
    # @return [Hash] Group size factors and maximum group size
    def group_size_factors(year, hios_id)
      Rails.cache.fetch("group_size_factors_#{year}_#{hios_id}", expires_in: 15.minutes) do
        factor = Products::ActuarialFactors::GroupSizeActuarialFactor.where(active_year: year,
                                                                            issuer_hios_id: hios_id).first
        if factor.nil?
          output = (1..50).each_with_object({}) do |key, result|
            result[key.to_s] = 1.0
          end
          max_group_size = 1
        else
          output = factor.actuarial_factor_entries.each_with_object({}) do |afe, result|
            result[afe.factor_key] = afe.factor_value
          end
          max_group_size = factor.max_integer_factor_key
        end

        { factors: output, max_group_size: }
      end
    end

    # Retrieves group tier factors for a given year and issuer
    # @param year [Integer] The year for which to retrieve factors
    # @param hios_id [String] The HIOS ID of the issuer
    # @return [Array<Hash>] Group tier factors with names and values
    def group_tier_factors(year, hios_id)
      Rails.cache.fetch("group_tier_factors_#{year}_#{hios_id}", expires_in: 15.minutes) do
        factor = Products::ActuarialFactors::CompositeRatingTierActuarialFactor.where(active_year: year,
                                                                                      issuer_hios_id: hios_id).first
        return [] if factor.nil?

        factor.actuarial_factor_entries.each_with_object([]) do |afe, result|
          key = TF_NAME_MAP[afe.factor_key]
          result << { factor: afe.factor_value, name: key }
        end
      end
    end

    # Retrieves participation factors for a given year and issuer
    # @param year [Integer] The year for which to retrieve factors
    # @param hios_id [String] The HIOS ID of the issuer
    # @return [Hash] Participation factors
    def participation_factors(year, hios_id)
      Rails.cache.fetch("participation_factors_#{year}_#{hios_id}", expires_in: 15.minutes) do
        factor = Products::ActuarialFactors::ParticipationRateActuarialFactor.where(active_year: year,
                                                                                    issuer_hios_id: hios_id).first
        if factor.nil?
          return (1..100).each_with_object({}) do |key, result|
                   result[key.to_s] = 1.0
                 end
        end

        factor.actuarial_factor_entries.each_with_object({}) do |afe, result|
          result[afe.factor_key] = afe.factor_value
        end
      end
    end

    # Additional helper methods for extracting and parsing specific service costs
    def pcp_in_network_copay(variance)
      val = variance.qhp_service_visits.where(visit_type: VISIT_TYPES[:pcp]).first.copay_in_network_tier_1
      parse_value(val)
    end

    def hospital_stay_in_network_copay(variance)
      val = variance.qhp_service_visits.where(visit_type: VISIT_TYPES[:hospital_stay]).first.copay_in_network_tier_1
      parse_value(val).nil? ? nil : format('%.2f', parse_value(val))
    end

    def emergency_in_network_copay(variance)
      val = variance.qhp_service_visits.where(visit_type: VISIT_TYPES[:emergency_stay]).first.copay_in_network_tier_1
      parse_value(val)
    end

    def drug_in_network_copay(variance)
      val = variance.qhp_service_visits.where(visit_type: VISIT_TYPES[:rx]).first.copay_in_network_tier_1
      parse_value(val)
    end

    def basic_dental_services(variance)
      variance.qhp_service_visits.where(
        visit_type: VISIT_TYPES[:basic_dental_services]
      ).first.co_insurance_in_network_tier_1
    end

    def major_dental_services(variance)
      visit = variance.qhp_service_visits.where(visit_type: VISIT_TYPES[:major_dental_services]).first
      visit&.co_insurance_in_network_tier_1
    end

    def preventive_dental_services(variance)
      variance.qhp_service_visits.where(
        visit_type: VISIT_TYPES[:preventive_dental_services]
      ).first.co_insurance_in_network_tier_1
    end

    def out_of_pocket_in_network(variance)
      variance.qhp_maximum_out_of_pockets.first.in_network_tier_1_family_amount
    end

    # Determines the metal level of the plan
    # @return [String] The metal level or 'dental' for dental plans
    def retrieve_metal_level
      health_product? ? qhp.metal_level.downcase : 'dental'
    end

    # Determines if the QHP is a health product or dental product
    # @return [Boolean] True if it's a health product, false if dental
    def health_product?
      qhp.dental_plan_only_ind.downcase == 'no'
    end

    # Parses the market type from the QHP data
    # @return [String] 'shop' or 'individual'
    def parse_market
      qhp.market_coverage = qhp.market_coverage.downcase.include?('shop') ? 'shop' : 'individual'
    end

    # Parses a value from a string format to a numeric format
    # @param val [String] The value to parse
    # @return [String, nil] The parsed value or nil if not applicable
    def parse_value(val)
      val == 'Not Applicable' ? nil : val.split[0].gsub('$', '').gsub(',', '')
    end

    # Extracts coinsurance for a specific service type
    # @param variance [Object] The cost share variance object
    # @param type [Symbol] The type of service
    # @return [String, nil] The coinsurance value or nil
    def service_visit_co_insurance(variance, type)
      val = variance.qhp_service_visits.where(visit_type: VISIT_TYPES[type]).first.co_insurance_in_network_tier_1
      val.present? ? parse_value(val) : nil
    end
  end
end
