# frozen_string_literal: true

# Base mailer class for all application mailers
# All other mailer classes should inherit from this class
# to maintain consistent defaults and layouts
class ApplicationMailer < ActionMailer::Base
  default from: 'from@example.com'
  layout 'mailer'
end
