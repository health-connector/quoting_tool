# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
# require "active_record/railtie"
# require "active_storage/engine"
require 'action_controller/railtie'
require 'action_mailer/railtie'
# require "action_mailbox/engine"
# require "action_text/engine"
require 'action_view/railtie'
# require "action_cable/engine"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Use the responders controller from the responders gem
    config.app_generators.scaffold_controller :responders_controller

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Disable static file serving from Rails which is causing compatibility issues with Ruby 3.1.6
    config.public_file_server.enabled = false

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.

    Rails.application.config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: %i[get post options put delete], expose: %w[Link Total]
      end
    end

    config.api_only = true
  end
end

Rails.configuration.after_initialize do
  # Load Current year & Next Year Products
  start_year = Date.today.year
  end_year = start_year + 1

  $rates = {}

  def quarter(val)
    (val / 3.0).ceil
  end

  ::Products::Product.where(
    :"application_period.min".gte => Date.new(start_year, 1,
                                              1), :"application_period.max".lte => Date.new(end_year, 1, 1).end_of_year
  ).each do |product|
    product.premium_tables.each do |pt|
      output = pt.premium_tuples.each_with_object({}) do |tuple, result|
        result[tuple.age] = tuple.cost
      end
      (quarter(pt.effective_period.min.month)..quarter(pt.effective_period.max.month)).each do |q|
        $rates[[product.id, pt.rating_area_id, q]] =
          { entries: output, max_age: product.premium_ages.max, min_age: product.premium_ages.min }
      end
    end
  end

  $sic_factors = {}

  Products::ActuarialFactors::SicActuarialFactor.all.where(:active_year.in => [start_year, end_year]).each do |factor|
    factor.actuarial_factor_entries.each do |entry|
      $sic_factors[[entry.factor_key, factor.active_year, factor.issuer_hios_id]] = entry.factor_value
    end
  end
end
