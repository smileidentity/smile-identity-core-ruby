# frozen_string_literal: true

require 'smile-identity-core'
require 'securerandom'
# See https://docs.smileidentity.com/products/for-businesses-kyb/business-verification for
# more information on business verification

# Initialize
partner_id = '<Put your partner ID here>'; # login to the Smile Identity portal to view your partner id
default_callback = '<Put your default callback url here>'
api_key = '<Put your API key here>'; # copy your API key from the Smile Identity portal
sid_server = '<0 | 1>'; # Use '0' for the sandbox server, use '1' for production server

connection = SmileIdentityCore::WebApi.new(partner_id, default_callback, api_key, sid_server)

# Create required tracking parameters
partner_params = {
  job_id: "job-#{SecureRandom.uuid}",
  user_id: "user-#{SecureRandom.uuid}",
  job_type: SmileIdentityCore::JobType::BUSINESS_VERIFICATION
}

# Create ID info
id_info = {
  # The country where ID document was issued
  country: '<2-letter country code>',
  # The ID document type
  id_type: '<id type>',
  # The business registration or tax number
  id_number: '<id number>',
  # The business incorporation type bn - business name, co - private/public limited, it - incorporated trustees
  # Only required for BASIC_BUSINESS_REGISTRATION and BUSINESS_REGISTRATION in Nigeria
  business_type: '<co | bn | it>'
}

# Submit the job
connection.submit_job(partner_params, [], id_info, {})
