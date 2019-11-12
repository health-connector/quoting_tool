class Api::V1::EmployeesController < ApplicationController
  respond_to :json

  def upload
    file = params.require(:file)
    @roster_upload_form = ::Transactions::LoadCensusRecords.new.call(file)

    if @roster_upload_form.success?
      render :json => {status: "success", census_records: @roster_upload_form.value!.values}
    else
      render :json => {status: "failure", census_records: [], errors: @roster_upload_form.failure}
    end
  end

  def download_roster
    object = resource.bucket(input[:bucket]).object(input[:key])
    encoded_result = Base64.encode64(object.get.body.read)

    if result.success?
      render json: { status: "success", metadata: encoded_result }
    else
      render json: { status: "failure", metadata: '' }
    end
  end
end
