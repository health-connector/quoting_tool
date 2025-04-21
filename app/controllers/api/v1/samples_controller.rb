class Api::V1::SamplesController < ApplicationController
  respond_to :json

  def index
    @sample = 'Your connected to the Rails Backend if your seeing this message'
    respond_with :api, :v1, json: { message: @sample }
  end
end
