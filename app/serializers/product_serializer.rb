# frozen_string_literal: true

# Serializes product data for the JSON API format.
# Handles both health and dental products, formatting their attributes
# appropriately for client consumption.
class ProductSerializer
  include JSONAPI::Serializer

  # Maps HIOS IDs to provider names for display purposes
  ProviderMap = {
    '36046' => 'Harvard Pilgrim Health Care',
    '80538' => 'Delta Dental',
    '11821' => 'Delta Dental',
    '31779' => 'UnitedHealthcare',
    '29125' => 'Tufts Health Premier',
    '38712' => 'Tufts Health Premier',
    '88806' => 'Fallon Health',
    '52710' => 'Fallon Health',
    '41304' => 'Mass General Brigham Health Plan',
    '18076' => 'Altus Dental',
    '34484' => 'Health New England',
    '59763' => 'Tufts Health Direct',
    '42690' => 'Blue Cross Blue Shield MA',
    '82569' => 'WellSense Health Plan'
  }.freeze

  # Basic product attributes shared between health and dental products
  attributes :deductible, :name, :group_size_factors, :group_tier_factors, :participation_factors, :hsa_eligible,
             :out_of_pocket_in_network

  # Package types the product is available in
  attribute :available_packages, &:product_package_kinds

  # Family/group deductible amount
  attribute :group_deductible, &:family_deductible

  # Network information/description
  attribute :network, &:network_information

  # Hospital stay coverage (health plans only)
  attribute :hospital_stay do |object|
    object.health? ? (object.hospital_stay_in_network_copay || object.hospital_stay_in_network_co_insurance) : nil
  end

  # Emergency room coverage (health plans only)
  attribute :emergency_stay do |object|
    object.health? ? (object.emergency_in_network_copay || object.emergency_in_network_co_insurance) : nil
  end

  # Primary care physician visit coverage (health plans only)
  attribute :pcp_office_visit do |object|
    object.health? ? (object.pcp_in_network_copay || object.pcp_in_network_co_insurance) : nil
  end

  # Prescription drug coverage (health plans only)
  attribute :rx do |object|
    object.health? ? (object.drug_in_network_copay || object.drug_in_network_co_insurance) : nil
  end

  # Basic dental services coverage (dental plans only)
  attribute :basic_dental_services do |object|
    object.dental? ? object.basic_dental_services : nil
  end

  # Major dental services coverage (dental plans only)
  attribute :major_dental_services do |object|
    object.dental? ? (object.major_dental_services || 'Not Applicable') : nil
  end

  # Preventive dental services coverage (dental plans only)
  attribute :preventive_dental_services do |object|
    object.dental? ? object.preventive_dental_services : nil
  end

  # Metal level (e.g., Bronze, Silver, Gold, Platinum)
  attribute :metal_level, &:metal_level_kind

  # Object ID as string
  attribute :id do |object|
    object.id.to_s
  end

  # Whether prescription drug deductible is integrated with medical
  attribute :integrated_drug_deductible do |_object|
    nil
  end

  # Product type (e.g., HMO, PPO, EPO for health; HMO, PPO for dental)
  attribute :product_type do |object|
    object.health? ? object.health_plan_kind : object.dental_plan_kind
  end

  # Insurance provider name
  attribute :provider_name do |object|
    ProviderMap[object.issuer_hios_ids.first]
  end

  # SIC code factor for the product
  attribute :sic_code_factor do |object, params|
    if object.dental?
      1.0
    else
      $sic_factors[[params[:key], object.active_year, object.issuer_hios_ids.first]] || 1.0
    end
  end

  # Premium rates for the product in the specified rating area and quarter
  attribute :rates do |object, params|
    Rails.cache.fetch("rates_#{object.id}_#{params[:rating_area_id]}_#{params[:quarter]}", expires_in: 45.minutes) do
      $rates[[object.id, params[:rating_area_id], params[:quarter]]]
    end
  end
end
