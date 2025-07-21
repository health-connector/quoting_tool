# frozen_string_literal: true

require 'application_responder'

# Base controller for the Quoting Tool API
# All other controllers inherit from this class
# Configured to use ApplicationResponder for standardized API responses
class ApplicationController < ActionController::API
  self.responder = ApplicationResponder
  respond_to :html
end
