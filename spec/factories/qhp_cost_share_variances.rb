# frozen_string_literal: true

FactoryBot.define do
  factory :qhp_cost_share_variance, class: 'Products::QhpCostShareVariance' do
    hios_plan_and_variant_id { '11111-01' }
    plan_marketing_name { 'Plan Name' }
  end
end
