# frozen_string_literal: true

module Api
  module V1
    # Sample controller to demonstrate API connectivity
    # This controller provides endpoints to verify that the API is functioning properly
    class SamplesController < ApplicationController
      respond_to :json

      # Returns a simple message to confirm API connectivity
      # @return [JSON] A success message confirming connection to the Rails backend
      def index
        @sample = 'Your connected to the Rails Backend if your seeing this message'
        respond_with :api, :v1, json: { message: @sample }
      end
    end
  end
end
