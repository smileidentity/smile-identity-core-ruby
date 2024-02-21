# frozen_string_literal: true

require 'smile-identity-core'

# See https://docs.usesmileid.com/server-to-server/ruby/products/biometric-kyc for
# how to setup and retrieve configuation values for the WebApi class.

# Initialize
partner_id = '<Put your partner ID here>'; # login to the Smile Identity portal to view your partner id
default_callback = '<Put your default callback url here>'
api_key = '<Put your API key here>'; # copy your API key from the Smile Identity portal
sid_server = '<0 | 1>'; # Use '0' for the sandbox server, use '1' for production server

connection = SmileIdentityCore::WebApi.new(partner_id, default_callback, api_key, sid_server)

# Create required tracking parameters
partner_params = {
  user_id: '<put your unique ID for the user here>',
  job_id: '<put your unique job ID here>',
  job_type: 1
}

# Create image list
# image_type_id Integer
# 0 - Selfie image jpg or png (if you have the full path of the selfie)
# 2 - Selfie image jpg or png base64 encoded (if you have the base64image string of the selfie)
# 4 - Liveness image jpg or png (if you have the full path of the liveness image)
# 6 - Liveness image jpg or png base64 encoded (if you have the base64image string of the liveness image)
image_details = [
  {
    image_type_id: '<0 | 2>',
    image: '<full path to selfie image or base64image string>'
  },
  { # Not required if you don't require proof of life (note photo of
    # photo check will still be performed on the uploaded selfie)
    image_type_id: '<4 | 6>',
    image: '<full path to liveness image or base64 image string>'
  }
]

# Create ID number info
id_info = {
  first_name: '<first name>',
  last_name: '<surname>',
  country: '<2-letter country code>',
  id_type: '<id type>',
  id_number: '<valid id number>',
  dob: '<date of birth>', # yyyy-mm-dd
  entered: 'true' # must be a string
}

# Set options for the job
options = {
  # Set to true if you want to get the job result in sync (in addition to the result been sent
  # to your callback). If set to false, result is sent to callback url only.
  return_job_status: '<true | false>',
  # Set to true to receive all of the updates you would otherwise have received in your callback
  # as opposed to only the final result. You must set return_job_status to true to use this flag.
  return_history: '<true | false>',
  # Set to true to receive links to the selfie and the photo
  # it was compared to. You must set return_job_status to true to use this flag.
  return_image_links: '<true | false>',
  signature: true
}

# Submit the job
connection.submit_job(partner_params, image_details, id_info, options)
