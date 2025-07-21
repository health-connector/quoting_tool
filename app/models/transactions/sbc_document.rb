# frozen_string_literal: true

module Transactions
  # Handles retrieval of Summary of Benefits and Coverage (SBC) documents from AWS S3.
  # Provides functionality to load, validate, and serve SBC documents for products.
  class SbcDocument
    include Dry::Transaction

    step :load
    step :validate
    step :serve

    private

    # Parses the input key for the document
    #
    # @param input [Hash] Contains the key identifying the product
    # @return [Dry::Monads::Result::Success] Hash containing the sanitized key
    def load(input)
      key = parse_text(input[:key])
      Success({ key: })
    end

    # Validates the key and retrieves the document identifier
    #
    # @param input [Hash] Contains the key from previous step
    # @return [Dry::Monads::Result] Success with identifier or Failure with error message
    def validate(input)
      return Failure({ message: 'Key should not be blank' }) if input[:key].blank?

      product = Products::Product.where(id: input[:key]).first

      return Failure({ message: 'Product/Sbc Document not found' }) if product.blank? || product.sbc_document.blank?

      Success({ identifier: product.sbc_document.identifier })
    end

    # Retrieves the document from S3 and returns it base64 encoded
    #
    # @param input [Hash] Contains the document identifier from previous step
    # @return [Dry::Monads::Result] Success with encoded document or Failure with error message
    def serve(input)
      bucket_name, key = input[:identifier].split(':').last.split('#')
      bucket = parse_bucket(bucket_name)

      object = resource.bucket(bucket).object(key)
      encoded_result = Base64.encode64(object.get.body.read)
      Success({ message: 'Successfully retrieved documents.', result: encoded_result })
    rescue StandardError => e
      Failure({ message: e.message })
    end

    # Creates an AWS S3 resource
    #
    # @return [Aws::S3::Resource] S3 resource for document retrieval
    def resource
      @resource ||= ::Aws::S3::Resource.new(client:)
    end

    # Creates an AWS S3 client
    #
    # @return [Aws::S3::Client] S3 client for document retrieval
    def client
      @client ||= ::Aws::S3::Client.new(stub_responses: stub?)
    end

    # Determines if responses should be stubbed based on environment
    #
    # @return [Boolean] True if in development or test environment
    def stub?
      Rails.env.local?
    end

    # Sanitizes text input by removing extra whitespace
    #
    # @param val [String, nil] Text to be sanitized
    # @return [String, nil] Sanitized text or nil
    def parse_text(val)
      return nil if val.nil?

      val.to_s.squish!
    end

    # Determines the S3 bucket name based on environment
    #
    # @param _val [String] Original bucket name (unused)
    # @return [String] Environment-specific bucket name
    def parse_bucket(_val)
      "mhc-enroll-sbc-#{env}" # get this from settings
    end

    # Gets the current AWS environment
    #
    # @return [String] AWS environment name
    def env
      ENV['AWS_ENV'] || 'qa'
    end
  end
end
