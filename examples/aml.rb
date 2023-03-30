# frozen_string_literal: true

require 'smile-identity-core'
require 'securerandom'
# See https://docs.smileidentity.com/products/for-businesses-kyb/business-verification for
# more information on business verification

# Initialize
partner_id = '<Your partner ID>' # login to the Smile Identity portal to view your partner id
api_key = '<Your API key>' # copy your API key from the Smile Identity portal
sid_server = '<0 or 1>' # Use 0 for the sandbox server, use 1 for production server

connection = SmileIdentityCore::Aml.new(partner_id, api_key, sid_server)

# Create required tracking parameters
partner_params = {
  job_id: "job-#{SecureRandom.uuid}",
  user_id: "user-#{SecureRandom.uuid}",
  job_type: SmileIdentityCore::JobType::AML,
  auto_reconcile: true
}

# Create ID info
id_info = {
  # An array that takes the customer’s known nationalities in 2-character format
  # e.g. Nigeria is NG, Kenya is KE, etc.
  countries: ['US'],
  full_name: 'John Leo Doe',
  birth_year: '1984'
}

# Set the options for the job
options = {
  # If you intend to re-use the name and year of birth of a user’s previous KYC job,
  # you can pass the string with the value set to True.
  search_existing_user: false
}

# Submit the job
pp connection.submit_job(partner_params, id_info, options)
