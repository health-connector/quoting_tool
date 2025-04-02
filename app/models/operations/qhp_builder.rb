module Operations
  class QhpBuilder
    include Dry::Transaction::Operation
    include Dry::Monads[:result]

    INVALID_PLAN_IDS = ["88806MA0020005", "88806MA0040005", "88806MA0020051", "18076MA0010001", "80538MA0020001", "80538MA0020002", "11821MA0020001", "11821MA0040001"]

    attr_accessor :package, :product, :qhp, :service_area_map, :health_data_map, :dental_data_map

    def call(params)
      @service_area_map = params[:service_area_map]
      @health_data_map = params[:health_data_map]
      @dental_data_map = params[:dental_data_map]
      packages = params[:packages]

      packages.each do |package|
        @package = package
        package[:plans_list][:plans].each do |product|
          @product = product
          build_objects(qhp_params)
        end
      end
      Success({message: "Successfully created/updated QHP records"})
    end

    def build_objects(params)
      @qhp = initialize_qhp(params)
      build_cost_share_variances_list
      validate_and_persist_qhp
    end

    def initialize_qhp(params)
      qhp = ::Products::Qhp.where(active_year: params[:active_year], standard_component_id: params[:standard_component_id]).first
      if qhp.present?
        qhp.attributes = params
        qhp.qhp_benefits = []
        qhp.qhp_cost_share_variances = []
      else
        qhp = ::Products::Qhp.new(params)
      end
      effective_date = qhp.plan_effective_date.to_date
      qhp.plan_effective_date = effective_date.beginning_of_year
      qhp.plan_expiration_date = effective_date.end_of_year
      benefits_params.each { |benefit| qhp.qhp_benefits.build(benefit) }
      qhp
    end

    def build_cost_share_variances_list
      cost_share_variance_list_params.each do |csvp|
        @csvp = csvp
        next if hios_plan_and_variant_id.split("-").last == "00"
        if hios_plan_and_variant_id.split("-").last == "01" && qhp.active_year > 2015
          qhp.hsa_eligibility = hsa_params[:hsa_eligibility]
        end

        qcsv = qhp.qhp_cost_share_variances.build(cost_share_variance_attributes)
        maximum_out_of_pockets_params.each do |moop|
          qcsv.qhp_maximum_out_of_pockets.build(moop)
        end

        service_visits_params.each do |svp|
          qcsv.qhp_service_visits.build(svp)
        end
        qcsv.build_qhp_deductable(deductible_params)
      end
    end

    def validate_and_persist_qhp
      if !INVALID_PLAN_IDS.include?(qhp.standard_component_id.strip)
        result = ProductBuilder.new.call({qhp: qhp, health_data_map: health_data_map, dental_data_map: dental_data_map, service_area_map: service_area_map})
        if qhp.save!
          Success({message: ["Succesfully created QHP"]})
        end
      end
    end

    def hios_plan_and_variant_id
      cost_share_variance_attributes[:hios_plan_and_variant_id]
    end

    def hsa_params
      @csvp[:hsa_attributes]
    end

    def service_visits_params
      @csvp[:service_visits_attributes]
    end

    def deductible_params
      @csvp[:deductible_attributes]
    end

    def maximum_out_of_pockets_params
      @csvp[:maximum_out_of_pockets_attributes]
    end

    def sbc_params
      @csvp[:sbc_attributes]
    end

    def cost_share_variance_attributes
      return @csvp[:cost_share_variance_attributes] if sbc_params.blank?
      @csvp[:cost_share_variance_attributes].merge!(sbc_params)
    end

    def qhp_params
      product[:plan_attributes][:active_year] = product[:plan_attributes][:plan_effective_date][-4..-1].to_i
      package[:header].merge!(product[:plan_attributes])
    end

    def benefits_params
      package[:benefits_list][:benefits]
    end

    def cost_share_variance_list_params
      product[:cost_share_variance_list_attributes]
    end
  end
end
