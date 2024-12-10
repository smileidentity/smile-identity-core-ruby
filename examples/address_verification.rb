# frozen_string_literal: true

require 'smile-identity-core'
# See https://docs.usesmileid.com/products/for-individuals-kyc/address-verification for
# more information on address verification

# Initialize
partner_id = '' # login to the Smile Identity portal to view your partner id
api_key = '' # copy your API key from the Smile Identity portal
sid_server = '0' # Use 0 for the sandbox server, use 1 for production server

## Mutually Exclusive Fields
# Fields specific to Nigeria (NG):
# utility_number: "12345678911", # (Required for NG) The utility account number.
# Format: numeric string, e.g., '12345678911'.
#
# utility_provider: "IkejaElectric", # (Required for NG) The utility provider.
# Must match an accepted provider name.

# Fields specific to South Africa (ZA):
# id_number: '1234567891234', # (Required for ZA) The national ID number.
# Format: numeric string of 13 digits.

connection = SmileIdentityCore::AddressVerification.new(partner_id, api_key, sid_server)

request_params = {
  country: 'ZA', # (Required) Must be 'NG' or 'ZA'.
  address: 'Cape Town', # (Required) Should be a valid and complete address.

  # Fields specific to Nigeria (NG):
  # utility_number: "12345678911", # (Required for NG) The utility account number.
  # utility_provider: "IkejaElectric", # (Required for NG) The utility provider.

  # Fields specific to South Africa (ZA):
  id_number: '1234567891234', # (Required for ZA) The 13 digits national ID number.

  full_name: 'Doe Joe Leo', # (Optional) The full name of the user for additional verification.
  callback_url: 'https://webhook.site', # (Required) The callback URL where the verification response will be sent.
}

# Response
# The response is sent to the callback_url specified in the request_params hash.
# It contains the verification status of the submitted address.
# {
# success: true,
# }

# Submit the job
pp connection.submit_job(request_params)
