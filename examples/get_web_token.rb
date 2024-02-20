# frozen_string_literal: true

require 'smile-identity-core'
require 'random/formatter'

# See https://docs.usesmileid.com/server-to-server/ruby/products/biometric-kyc for
# how to setup and retrieve configuation values for the WebApi class.

# Initialize
partner_id = '<Put your partner ID here>'; # login to the Smile Identity portal to view your partner id
default_callback = '<Put your default callback url here>'
api_key = '<Put your API key here>'; # copy your API key from the Smile Identity portal
sid_server = '<0 | 1>'; # Use '0' for the sandbox server, use '1' for production server

connection = SmileIdentityCore::WebApi.new(partner_id, default_callback, api_key, sid_server)

# Set up request payload
request_params = {
  user_id: '<your unique user id>',
  job_id: '<your unique job id>',
  product: '<smile identity product type>',
  callback_url: '<your callback url>'
}

# Get web token
connection.get_web_token(request_params)
