# frozen_string_literal: true

require 'smile-identity-core'
require 'securerandom'
# See https://docs.smileidentity.com/server-to-server/ruby/products/enhanced-kyc for
# how to setup and retrieve configuation values for the IDApi class.

# Initialize
partner_id = '<Put your partner ID here>'; # login to the Smile Identity portal to view your partner id
default_callback = '<Put your default callback url here>'
api_key = '<Put your API key here>'; # copy your API key from the Smile Identity portal
sid_server = '<0 | 1>'; # Use '0' for the sandbox server, use '1' for production server

connection = SmileIdentityCore::BusinessVerification.new(partner_id, '', api_key, sid_server)

# Create required tracking parameters
partner_params = {
  job_id: "job-#{SecureRandom.uuid}",
  user_id: "user-#{SecureRandom.uuid}",
  job_type: SmileIdentityCore::JobType::BUSINESS_VERIFICATION
}

# Create ID info
id_info = {
  country: '<2-letter country code>', # The country where ID document was issued
  id_type: '<id type>', # The ID document type
  id_number: '0000000', # The business registration or tax number
  business_type: 'co'
}

# Submit the job
response = connection.submit_job(partner_params, id_info)
