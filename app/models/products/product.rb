# frozen_string_literal: true

# Support product import from SERFF, CSV templates, etc

# Effective dates during which sponsor may purchase this product at this price
## DC SHOP Health   - annual product changes & quarterly rate changes
## CCA SHOP Health  - annual product changes & quarterly rate changes
## DC IVL Health    - annual product & rate changes
## Medicare         - annual product & semiannual rate changes

module Products
  # The Product class represents an insurance product that can be offered to customers.
  # It contains basic attributes, premium information, and methods for managing
  # product lifecycle and premium calculations.
  #
  # Products can be health or dental insurance policies with various benefit structures.
  # This base class provides the common functionality for all product types.
  class Product
    include Mongoid::Document
    include Mongoid::Timestamps

    # Available benefit market types for products
    BENEFIT_MARKET_KINDS = %i[aca_shop aca_individual fehb medicaid medicare].freeze

    # The market segment this product belongs to (e.g., aca_shop, aca_individual)
    field :benefit_market_kind,   type: Symbol

    # Time period during which Sponsor may include this product in benefit application
    # Example: Mon, 01 Jan 2018..Mon, 31 Dec 2018
    field :application_period,    type: Range

    # Unique identifier within Health Benefit Exchange
    field :hbx_id,                type: String
    # Marketing name of the product
    field :title,                 type: String
    # Detailed description of the product
    field :description,           type: String,         default: ''
    # List of HIOS IDs associated with the issuer
    field :issuer_hios_ids,       type: Array,          default: []
    # Types of product packages this product can be included in
    field :product_package_kinds, type: Array,          default: []
    # Type of product (e.g., health, dental)
    field :kind,                  type: Symbol,         default: -> { product_kind }
    # Age range for premium calculations
    field :premium_ages,          type: Range,          default: 0..65
    # URL to the provider directory
    field :provider_directory_url,      type: String
    # Indicates if this product can be used as a reference plan
    field :is_reference_plan_eligible,  type: Boolean, default: false

    # Medical deductible amount as a formatted string (e.g., "$500")
    field :deductible, type: String
    # Family deductible amount as a formatted string
    field :family_deductible, type: String
    # ID assigned by the issuer
    field :issuer_assigned_id, type: String
    # Reference to the service area this product is offered in
    field :service_area_id, type: BSON::ObjectId
    # Information about the product's network
    field :network_information, type: String

    # Factors used for adjusting premiums based on group size
    field :group_size_factors, type: Hash
    # Factors used for adjusting premiums based on tier
    field :group_tier_factors, type: Array
    # Factors used for adjusting premiums based on participation
    field :participation_factors, type: Hash
    # Indicates if the product is HSA-eligible
    field :hsa_eligible, type: Boolean

    # Out-of-pocket maximum for in-network services
    field :out_of_pocket_in_network, type: String

    # Summary of Benefits and Coverage document
    embeds_one  :sbc_document,
                class_name: 'Documents::Document', as: :documentable

    # Premium rate tables for this product
    embeds_many :premium_tables,
                class_name: '::Products::PremiumTable'

    # validates_presence_of :hbx_id
    validates :application_period, :benefit_market_kind, :title, :service_area, presence: true

    validates :benefit_market_kind,
              presence: true,
              inclusion: { in: BENEFIT_MARKET_KINDS, message: '%<value>s is not a valid benefit market kind' }

    # Database indexes for improved query performance
    index({ hbx_id: 1 }, { name: 'products_hbx_id_index' })
    index({ service_area_id: 1 }, { name: 'products_service_area_index' })

    index({ 'application_period.min' => 1,
            'application_period.max' => 1 },
          { name: 'products_application_period_index' })

    index({ 'benefit_market_kind' => 1,
            'kind' => 1,
            'product_package_kinds' => 1 },
          { name: 'product_market_kind_product_package_kind_index' })

    index({ 'premium_tables.effective_period.min' => 1,
            'premium_tables.effective_period.max' => 1 },
          { name: 'products_premium_tables_effective_period_index' })

    index({ 'benefit_market_kind' => 1,
            'kind' => 1,
            'product_package_kinds' => 1,
            'application_period.min' => 1,
            'application_period.max' => 1 },
          { name: 'products_product_package_date_search_index' })

    index({ 'premium_tables.rating_area' => 1,
            'premium_tables.effective_period.min' => 1,
            'premium_tables.effective_period.max' => 1 },
          { name: 'products_premium_tables_search_index' })

    # Scopes for filtering products
    scope :by_product_package, lambda { |product_package|
                                 by_application_period(product_package.application_period).where(
                                   :benefit_market_kind => product_package.benefit_kind,
                                   :kind => product_package.product_kind,
                                   :product_package_kinds.in => [product_package.package_kind]
                                 )
                               }

    scope :aca_shop_market,             -> { where(benefit_market_kind: :aca_shop) }
    scope :aca_individual_market,       -> { where(benefit_market_kind: :aca_individual) }
    scope :by_kind,                     ->(kind) { where(kind:) }
    scope :by_service_area,             ->(service_area) { where(service_area:) }
    scope :by_service_areas,            lambda { |service_area_ids|
                                          where('service_area_id' => { '$in' => service_area_ids })
                                        }

    scope :by_metal_level_kind,         ->(metal_level) { where(metal_level_kind: /#{metal_level}/i) }

    scope :effective_with_premiums_on,  lambda  { |effective_date|
                                          where(:'premium_tables.effective_period.min'.lte => effective_date,
                                                :'premium_tables.effective_period.max'.gte => effective_date)
                                        }

    # input: application_period type: :Date
    # ex: application_period --> [2018-02-01 00:00:00 UTC..2019-01-31 00:00:00 UTC]
    #     BenefitProduct avilable for both 2018 and 2019
    # output: might pull multiple records
    scope :by_application_period,       lambda  { |application_period|
      where(
        '$or' => [
          { 'application_period.min' => { '$lte' => application_period.max, '$gte' => application_period.min } },
          { 'application_period.max' => { '$lte' => application_period.max, '$gte' => application_period.min } },
          { 'application_period.min' => { '$lte' => application_period.min },
            'application_period.max' => { '$gte' => application_period.max } }
        ]
      )
    }

    # Products retrieval by type
    scope :health_products,            -> { where(_type: /.*HealthProduct$/) }
    scope :dental_products,            -> { where(_type: /.*DentalProduct$/) }

    # Highly nested scopes don't behave in a way I entirely understand with
    # respect to the $elemMatch operator.  Since we are only invoking this
    # method when we already have the document, I'm going to abuse lazy
    # enumeration to create something that behaves like a scope but will
    # only be evaluated once.
    # Returns products that are available during the given application period
    # and have premium tables effective on the given date
    # @param collection [Array<Product>] Products to filter
    # @param coverage_date [Date] Date to check premium table effectiveness
    # @return [Array<Product>] Filtered products
    def self.by_coverage_date(collection, coverage_date)
      collection.select do |product|
        product.premium_tables.any? do |pt|
          (pt.effective_period.min <= coverage_date) && (pt.effective_period.max >= coverage_date)
        end
      end
    end

    # Sets the service area ID and caches the service area object
    # @param val [BSON::ObjectId] The service area ID
    def service_area_id=(val)
      write_attribute(:service_area_id, val)
      @service_area = if val.nil?
                        nil
                      else
                        ::Locations::ServiceArea.find(service_area_id)
                      end
    end

    # Sets the service area object and updates the service area ID
    # @param val [::Locations::ServiceArea] The service area object
    def service_area=(val)
      @service_area = val
      self[:service_area_id] = if val.nil?
                                 nil
                               else
                                 val.id
                               end
    end

    # Returns the Essential Health Benefits percentage
    # @return [Numeric] EHB percentage (defaults to 1 if not set or zero)
    def ehb
      percent = read_attribute(:ehb)
      percent&.positive? ? percent : 1
    end

    # Retrieves the service area object associated with this product
    # @return [::Locations::ServiceArea, nil] The service area or nil if not set
    def service_area
      return nil if service_area_id.blank?

      @service_area ||= ::Locations::ServiceArea.find(service_area_id)
    end

    # Returns the product title as the name
    # @return [String] Product title
    def name
      title
    end

    # Calculates the minimum premium cost for the given effective date
    # @param effective_date [Date] Date to check premium for
    # @return [Numeric, nil] Minimum premium cost or nil if no premium tables
    def min_cost_for_application_period(effective_date)
      p_tables = premium_tables.effective_period_cover(effective_date)
      return unless premium_tables.any?

      p_tables.flat_map(&:premium_tuples).select do |pt|
        pt.age == premium_ages.min
      end.min_by(&:cost).cost
    end

    # Calculates the maximum premium cost for the given effective date
    # @param effective_date [Date] Date to check premium for
    # @return [Numeric, nil] Maximum premium cost or nil if no premium tables
    def max_cost_for_application_period(effective_date)
      p_tables = premium_tables.effective_period_cover(effective_date)
      return unless premium_tables.any?

      p_tables.flat_map(&:premium_tuples).select do |pt|
        pt.age == premium_ages.min
      end.max_by(&:cost).cost
    end

    # Calculates the cost for the given application period
    # @param application_period [Range] Date range for the application period
    # @return [Numeric, nil] Premium cost or nil if no premium tables
    def cost_for_application_period(application_period)
      p_tables = premium_tables.effective_period_cover(application_period.min)
      return unless premium_tables.any?

      p_tables.flat_map(&:premium_tuples).select do |pt|
        pt.age == premium_ages.min
      end.min_by(&:cost).cost
    end

    # Extracts the numeric deductible value from the deductible string
    # @return [Integer, nil] Deductible amount as an integer or nil if not set
    def deductible_value
      return nil if deductible.blank?

      deductible.split('.').first.gsub(/[^0-9]/, '').to_i
    end

    # Extracts the numeric family deductible value from the family deductible string
    # @return [Integer, nil] Family deductible amount as an integer or nil if not set
    def family_deductible_value
      return nil if family_deductible.blank?

      deductible.split('|').last.split('.').first.gsub(/[^0-9]/, '').to_i
    end

    # Determines the product kind based on the class name
    # @return [Symbol] Type of product
    def product_kind
      kind_string = self.class.to_s.demodulize.sub!('Product', '').downcase
      kind_string.present? ? kind_string.to_sym : :product_base_class
    end

    # Lists attributes used for comparing products
    # @return [Array<Symbol>] List of attributes for comparison
    def comparable_attrs
      %i[
        hbx_id benefit_market_kind application_period title description
        issuer_profile_id service_area
      ]
    end

    # Define Comparable operator
    # If instance attributes are the same, compare PremiumTables
    # @param other [Product] Another product to compare with
    # @return [Integer] -1, 0, or 1 based on comparison result
    def <=>(other)
      if comparable_attrs.all? { |attr| send(attr) == other.send(attr) }
        if premium_tables.count == other.premium_tables.count
          premium_tables.to_a <=> other.premium_tables.to_a
        else
          premium_tables.count <=> other.premium_tables.count
        end
      else
        other.updated_at.blank? || (updated_at < other.updated_at) ? -1 : 1
      end
    end

    # Returns the year component of the application period's start date
    # @return [Integer] Year value
    def active_year
      application_period.min.year
    end

    # Finds the premium table effective on the specified date
    # @param effective_date [Date] Date to check
    # @return [PremiumTable, nil] Premium table or nil if none found
    def premium_table_effective_on(effective_date)
      premium_tables.detect { |premium_table| premium_table.effective_period.cover?(effective_date) }
    end

    # Add premium table, covering extended time period, to existing product.
    # Used for products that have periodic rate changes, such as ACA SHOP products
    # that are updated quarterly.
    #
    # @param new_premium_table [PremiumTable] Premium table to add
    # @raise [InvalidEffectivePeriodError] If the premium table's effective period is invalid
    # @raise [DuplicatePremiumTableError] If a premium table already exists for the period
    # @return [Product] Self
    def add_premium_table(new_premium_table)
      raise InvalidEffectivePeriodError unless is_valid_premium_table_effective_period?(new_premium_table)

      if premium_table_effective_on(new_premium_table.effective_period.min).present? ||
         premium_table_effective_on(new_premium_table.effective_period.max).present?
        raise DuplicatePremiumTableError, 'effective_period may not overlap existing premium_table'
      else
        premium_tables << new_premium_table
      end

      self
    end

    # Updates an existing premium table with new values
    # @param updated_premium_table [PremiumTable] Updated premium table
    # @raise [InvalidEffectivePeriodError] If the premium table's effective period is invalid
    # @return [Product] Self
    def update_premium_table(updated_premium_table)
      raise InvalidEffectivePeriodError unless is_valid_premium_table_effective_period?(updated_premium_table)

      drop_premium_table(premium_table_effective_on(updated_premium_table.effective_period.min))
      add_premium_table(updated_premium_table)
    end

    # Removes a premium table from this product
    # @param premium_table [PremiumTable] Premium table to remove
    def drop_premium_table(premium_table)
      premium_tables.delete(premium_table) if premium_table.present?
    end

    # Validates whether a premium table's effective period is valid for this product
    # @param compare_premium_table [PremiumTable] Premium table to validate
    # @return [Boolean] True if valid, false otherwise
    def is_valid_premium_table_effective_period?(compare_premium_table)
      return false unless application_period.present? && compare_premium_table.effective_period.present?

      application_period.cover?(compare_premium_table.effective_period.min) &&
        application_period.cover?(compare_premium_table.effective_period.max)
    end

    # Adds a product package to this product
    # @param new_product_package [ProductPackage] Product package to add
    # @return [Array] Updated list of product packages
    def add_product_package(new_product_package)
      product_packages.push(new_product_package).uniq!
      product_packages
    end

    # Removes a product package from this product
    # @param product_package [ProductPackage] Product package to remove
    # @return [ProductPackage, String] Removed product package or "not found" message
    def drop_product_package(product_package)
      product_packages.delete(product_package) { 'not found' }
    end

    # Checks if this is a health product
    # @return [Boolean] True if this is a health product
    def health?
      kind == :health
    end

    # Checks if this is a dental product
    # @return [Boolean] True if this is a dental product
    def dental?
      kind == :dental
    end
  end
end
