# frozen_string_literal: true

module Parsers
  module Products
    class PlanRateGroupParser
      include HappyMapper

      tag 'qhpApplicationRateGroupVO'

      has_one :header, Parsers::Products::PlanRateHeaderParser, tag: 'header'
      has_many :items, Parsers::Products::PlanRateItemsParser, tag: 'items'

      def to_hash
        {
          header: header.to_hash,
          items: items.map(&:to_hash)
        }
      end
    end
  end
end
