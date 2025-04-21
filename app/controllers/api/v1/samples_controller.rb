# frozen_string_literal: true

module Api
  module V1
    class SamplesController < ApplicationController
      respond_to :json

      def index
        @sample = 'Your connected to the Rails Backend if your seeing this message'
        respond_with :api, :v1, json: { message: @sample }
      end
    end
  end
end
