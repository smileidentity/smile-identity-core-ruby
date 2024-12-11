# frozen_string_literal: true

require 'smile-identity-core'
# See https://docs.usesmileid.com/products/for-individuals-kyc/address-verification for
# more information on address verification

# Initialize
partner_id = '' # login to the Smile Identity portal to view your partner id
api_key = '' # copy your API key from the Smile Identity portal
sid_server = '0' # Use 0 for the sandbox server, use 1 for production server

# Array of example cases for different countries
example_cases = [
  {
    description: 'Example for South Africa (ZA)',
    request_params: {
      country: 'ZA', # (Required) Must be 'NG' or 'ZA'.
      address: 'Cape Town', # (Required) A valid and complete address.
      id_number: '1234567891234', # (Required for ZA) The 13-digit national ID number.
      full_name: 'Doe Joe Leo', # (Optional) Full name for additional verification.
      callback_url: 'https://webhook.site', # (Required) Callback URL for the response.
    },
  },
  {
    description: 'Example for Nigeria (NG)',
    request_params: {
      country: 'NG', # (Required) Must be 'NG' or 'ZA'.
      address: 'Lagos', # (Required) A valid and complete address.
      utility_number: '12345678911', # (Required for NG) Utility account number.
      utility_provider: 'IkejaElectric', # (Required for NG) Utility provider name.
      full_name: 'John Doe', # (Optional) Full name for additional verification.
      callback_url: 'https://webhook.site', # (Required) Callback URL for the response.
    },
  },
]

# Create a connection object
connection = SmileIdentityCore::AddressVerification.new(partner_id, api_key, sid_server)

# Loop through the example cases and make requests
example_cases.each do |example|
  puts example[:description]
  response = connection.submit_job(example[:request_params])
  pp response
end
