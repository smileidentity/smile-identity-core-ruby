# frozen_string_literal: true

require 'smile-identity-core'
# See https://docs.usesmileid.com/products/for-individuals-kyc/address-verification for
# more information on address verification

# Initialize
partner_id = '' # login to the Smile Identity portal to view your partner id
api_key = '' # copy your API key from the Smile Identity portal
sid_server = '0' # Use 0 for the sandbox server, use 1 for production server

connection = SmileIdentityCore::AddressVerification.new(partner_id, api_key, sid_server)

request_params = {
  country: 'ZA', # The country [NG, ZA] where the address is located
  address: 'Cape town', # The address to be verified
  # utility_number: "12345678911", # The utility number to be verified specifically for NG
  # utility_provider: "IkejaElectric", # The utility provider to be verified specifically for NG
  id_number: '1234567891234', # The ZA ID number of the user to be verified specifically for ZA
  full_name: 'Doe Joe Leo', # The full name of the user to be verified optionally
  callback_url: 'https://webhook.site', # The callback URL to receive the response
}

# Submit the job
pp connection.submit_job(request_params)
