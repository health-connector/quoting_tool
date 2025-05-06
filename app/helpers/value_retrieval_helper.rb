# frozen_string_literal: true

# The ValueRetrievalHelper module provides utility methods for handling data values
# in a safe and consistent manner. It offers functionality to sanitize and
# standardize input values, particularly for display or processing purposes.
#
# This module is designed to be included in classes that need to work with
# potentially unsafe or inconsistently formatted string values from various sources
# like user input, APIs, or database records.
#
# @example
#   include ValueRetrievalHelper
#
#   def process_user_input(input)
#     clean_value = safely_retrive_value(input)
#     # Further processing with clean_value
#   end
#
module ValueRetrievalHelper
  # Helper method to safely retrieve and clean values
  # @param value [String] The value to be cleaned
  # @return [String] Cleaned value, or an empty string if nil
  # This method removes newline characters and dollar signs from the value
  # and ensures that nil values are converted to empty strings.
  # It is used to sanitize the data before returning it in the hash.
  def safely_retrive_value(value)
    if value.present?
      value.gsub("\n", '').gsub('$', '').strip
    else
      ''
    end
  end

end