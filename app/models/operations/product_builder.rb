# frozen_string_literal: true

module Operations
  class ProductBuilder
    include Dry::Transaction::Operation
    include Dry::Monads[:result]

    VISIT_TYPES = {
      pcp: 'Primary Care Visit to Treat an Injury or Illness',
      emergency_stay: 'Emergency Room Services',
      hospital_stay: 'Inpatient Hospital Services (e.g., Hospital Stay)',
      rx: 'Generic Drugs',
      basic_dental_services: 'Basic Dental Care - Adult',
      major_dental_services: 'Major Dental Care - Adult',
      preventive_dental_services: 'Routine Dental Services (Adult)'
    }.freeze

    TF_NAME_MAP = {
      'employee_only' => 'Employee Only',
      'employee_and_spouse' => 'Employee and Spouse',
      'employee_and_one_or_more_dependents' => 'Employee and Dependents',
      'family' => 'Family'
    }.freeze

    attr_accessor :qhp, :health_data_map, :dental_data_map

    def call(params)
      @qhp = params[:qhp]
      @health_data_map = params[:health_data_map]
      @dental_data_map = params[:dental_data_map]
      created_product = nil

      @qhp.qhp_cost_share_variances.each do |cost_share_variance|
        hios_base_id, csr_variant_id = cost_share_variance.hios_plan_and_variant_id.split('-')
        next if csr_variant_id == '00'

        csr_variant_id = retrieve_metal_level == 'dental' ? '' : csr_variant_id
        product = ::Products::Product.where(
          :hios_base_id => hios_base_id,
          :csr_variant_id => csr_variant_id,
          :"application_period.min".gte => Date.new(qhp.active_year, 1, 1), :"application_period.max".lte => Date.new(qhp.active_year, 1, 1).end_of_year
        ).first

        service_area_id = if params[:service_area_map].present?
                            params[:service_area_map][[qhp.issuer_id, qhp.service_area_id, qhp.active_year]]
                          end

        shared_attrs = {
          benefit_market_kind: "aca_#{parse_market}",
          title: cost_share_variance.plan_marketing_name.squish,
          hios_id: is_health_product? ? cost_share_variance.hios_plan_and_variant_id : hios_base_id,
          hios_base_id:,
          csr_variant_id:,
          application_period: (Date.new(qhp.active_year, 1, 1)..Date.new(qhp.active_year, 12, 31)),
          service_area_id:,
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

        attrs = if is_health_product?
                  info = health_data_map[[hios_base_id, qhp.active_year]] || {}
                  {
                    health_plan_kind: qhp.plan_type.downcase,
                    ehb: qhp.ehb_percent_premium.present? ? qhp.ehb_percent_premium : 1.0,
                    pcp_in_network_copay: pcp_in_network_copay(cost_share_variance),
                    hospital_stay_in_network_copay: hospital_stay_in_network_copay(cost_share_variance),
                    emergency_in_network_copay: emergency_in_network_copay(cost_share_variance),
                    drug_in_network_copay: drug_in_network_copay(cost_share_variance),
                    pcp_in_network_co_insurance: service_visit_co_insurance(cost_share_variance, :pcp),
                    hospital_stay_in_network_co_insurance: service_visit_co_insurance(cost_share_variance,
                                                                                      :hospital_stay),
                    emergency_in_network_co_insurance: service_visit_co_insurance(cost_share_variance, :emergency_stay),
                    drug_in_network_co_insurance: service_visit_co_insurance(cost_share_variance, :rx),
                    is_standard_plan: info[:is_standard_plan],
                    network_information: info[:network_information],
                    title: (info[:title] || cost_share_variance.plan_marketing_name.squish!),
                    product_package_kinds: info[:product_package_kinds],
                    rx_formulary_url: info[:rx_formulary_url],
                    provider_directory_url: info[:provider_directory_url]
                  }
                else
                  info = dental_data_map[[hios_base_id, qhp.active_year]] || {}
                  {
                    dental_plan_kind: qhp.plan_type.downcase,
                    dental_level: qhp.metal_level.downcase,
                    product_package_kinds: ::Products::DentalProduct::PRODUCT_PACKAGE_KINDS,
                    is_standard_plan: info[:is_standard_plan],
                    network_information: info[:network_information],
                    title: (info[:title] || cost_share_variance.plan_marketing_name.squish!),
                    provider_directory_url: info[:provider_directory_url],
                    basic_dental_services: basic_dental_services(cost_share_variance),
                    major_dental_services: major_dental_services(cost_share_variance),
                    preventive_dental_services: preventive_dental_services(cost_share_variance)
                  }
                end.merge(shared_attrs)

        if product.present?
          product.issuer_hios_ids += [qhp.issuer_id]
          product.issuer_hios_ids = product.issuer_hios_ids.uniq
          product.update_attributes!(attrs)
          cost_share_variance.product_id = product.id if cost_share_variance.product_id.blank?
          created_product = product
        else
          attrs.merge!({ issuer_hios_ids: [qhp.issuer_id] })
          new_product = if is_health_product?
                          ::Products::HealthProduct.new(attrs)
                        else
                          ::Products::DentalProduct.new(attrs)
                        end

          if new_product.save!
            cost_share_variance.product_id = new_product.id
            created_product = new_product
          end
        end
      end

      Success({ message: 'Successfully created/updated Plan records', product: created_product })
    end

    def group_size_factors(year, hios_id)
      Rails.cache.fetch("group_size_factors_#{year}_#{hios_id}", expires_in: 15.minutes) do
        factor = Products::ActuarialFactors::GroupSizeActuarialFactor.where("active_year": year,
                                                                            "issuer_hios_id": hios_id).first
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

    def group_tier_factors(year, hios_id)
      Rails.cache.fetch("group_tier_factors_#{year}_#{hios_id}", expires_in: 15.minutes) do
        factor = Products::ActuarialFactors::CompositeRatingTierActuarialFactor.where("active_year": year,
                                                                                      "issuer_hios_id": hios_id).first
        return [] if factor.nil?

        factor.actuarial_factor_entries.each_with_object([]) do |afe, result|
          key = TF_NAME_MAP[afe.factor_key]
          result << { factor: afe.factor_value, name: key }
        end
      end
    end

    def participation_factors(year, hios_id)
      Rails.cache.fetch("participation_factors_#{year}_#{hios_id}", expires_in: 15.minutes) do
        factor = Products::ActuarialFactors::ParticipationRateActuarialFactor.where("active_year": year,
                                                                                    "issuer_hios_id": hios_id).first
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

    def pcp_in_network_copay(variance)
      val = variance.qhp_service_visits.where(visit_type: VISIT_TYPES[:pcp]).first.copay_in_network_tier_1
      parse_value(val)
    end

    def hospital_stay_in_network_copay(variance)
      val = variance.qhp_service_visits.where(visit_type: VISIT_TYPES[:hospital_stay]).first.copay_in_network_tier_1
      parse_value(val).nil? ? nil : ('%.2f' % parse_value(val))
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
      variance.qhp_service_visits.where(visit_type: VISIT_TYPES[:basic_dental_services]).first.co_insurance_in_network_tier_1
    end

    def major_dental_services(variance)
      visit = variance.qhp_service_visits.where(visit_type: VISIT_TYPES[:major_dental_services]).first
      visit&.co_insurance_in_network_tier_1
    end

    def preventive_dental_services(variance)
      variance.qhp_service_visits.where(visit_type: VISIT_TYPES[:preventive_dental_services]).first.co_insurance_in_network_tier_1
    end

    def out_of_pocket_in_network(variance)
      variance.qhp_maximum_out_of_pockets.first.in_network_tier_1_family_amount
    end

    def retrieve_metal_level
      is_health_product? ? qhp.metal_level.downcase : 'dental'
    end

    def is_health_product?
      qhp.dental_plan_only_ind.downcase == 'no'
    end

    def parse_market
      qhp.market_coverage = qhp.market_coverage.downcase.include?('shop') ? 'shop' : 'individual'
    end

    def parse_value(val)
      val == 'Not Applicable' ? nil : val.split(' ')[0].gsub('$', '').gsub(',', '')
    end

    def service_visit_co_insurance(variance, type)
      val = variance.qhp_service_visits.where(visit_type: VISIT_TYPES[type]).first.co_insurance_in_network_tier_1
      val.present? ? parse_value(val) : nil
    end
  end
end
