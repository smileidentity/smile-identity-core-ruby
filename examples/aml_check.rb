# frozen_string_literal: true

require 'smile-identity-core'
require 'securerandom'
# See https://docs.usesmileid.com/products/for-individuals-kyc/aml-check for
# more information on business verification

# Initialize
partner_id = '' # login to the Smile Identity portal to view your partner id
api_key = '' # copy your API key from the Smile Identity portal
sid_server = '0' # Use 0 for the sandbox server, use 1 for production server

connection = SmileIdentityCore::AmlCheck.new(partner_id, api_key, sid_server)

request_params = {
  job_id: "job-#{SecureRandom.uuid}",
  user_id: "user-#{SecureRandom.uuid}",
  full_name: 'John Leo Doe',
  countries: ['US'],
  birth_year: '1984', # yyyy
  search_existing_user: false,
}

# Submit the job
pp connection.submit_job(request_params)
