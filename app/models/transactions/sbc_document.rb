# frozen_string_literal: true

module Transactions
  class SbcDocument
    include Dry::Transaction

    step :load
    step :validate
    step :serve

    private

    def load(input)
      key = parse_text(input[:key])
      Success({ key: })
    end

    def validate(input)
      return Failure({ message: 'Key should not be blank' }) if input[:key].blank?

      product = Products::Product.where(id: input[:key]).first

      return Failure({ message: 'Product/Sbc Document not found' }) if product.blank? || product.sbc_document.blank?

      Success({ identifier: product.sbc_document.identifier })
    end

    def serve(input)
      bucket_name, key = input[:identifier].split(':').last.split('#')
      bucket = parse_bucket(bucket_name)

      object = resource.bucket(bucket).object(key)
      encoded_result = Base64.encode64(object.get.body.read)
      Success({ message: 'Successfully retrieved documents.', result: encoded_result })
    rescue Exception => e
      Failure({ message: e.message })
    end

    def resource
      @resource ||= ::Aws::S3::Resource.new(client:)
    end

    def client
      @client ||= ::Aws::S3::Client.new(stub_responses: stub?)
    end

    def stub?
      Rails.env.development? || Rails.env.test?
    end

    def parse_text(val)
      return nil if val.nil?

      val.to_s.squish!
    end

    def parse_bucket(_val)
      "mhc-enroll-sbc-#{env}" # get this from settings
    end

    def env
      ENV['AWS_ENV'] || 'qa'
    end
  end
end
