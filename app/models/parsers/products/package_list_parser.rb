# frozen_string_literal: true

module Parsers
  module Products
    # Parses the package list section from plan benefit templates
    # Acts as a container for multiple packages within the template
    class PackageListParser
      include HappyMapper

      tag 'packagesList'

      # Collection of package objects
      has_many :packages, PackageParser, tag: 'packages', dependent: :destroy

      # Converts the parsed package list data into a structured hash format
      # @return [Hash] Collection of package hashes
      def to_hash
        {
          packages: packages.map(&:to_hash)
        }
      end
    end
  end
end
