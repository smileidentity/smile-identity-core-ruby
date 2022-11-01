# frozen_string_literal: true

require 'dotenv/load'
require 'smile-identity-core'
require 'securerandom'
require 'json'

# SmartBank is a fictional banking app
class SmartBank
  attr_reader :partner_id, :default_callback, :api_key, :sid_server, :user_id, :job_id

  def initialize
    @partner_id = ENV['SMILE_PARTNER_ID'] # login to the Smile Identity portal to view your partner id
    @default_callback = ENV['SMILE_JOB_CALLBACK_URL'] # See https://docs.smileidentity.com/server-to-server/ruby/products/biometric-kyc#create-a-callback-endpoint
    @api_key = ENV['SMILE_API_KEY'] # copy your API key from the Smile Identity portal
    @sid_server = ENV['SMILE_SERVER_ENVIRONMENT'] # Use '0' for the sandbox server, use '1' for production server
    @user_id = SecureRandom.uuid # your unique ID for the user
    @job_id = SecureRandom.uuid # your unique job ID
  end

  # Public: Makes a request to query the Identity Information for an individual using
  # their ID number from one of our supported ID Types.
  #
  # Returns a verification result Hash
  def perform_enhanced_kyc
    connection = SmileIdentityCore::IDApi.new(partner_id, api_key, sid_server)

    # Create ID info
    id_info = {
      first_name: 'John',
      last_name: 'Doe',
      country: 'GH', # 2-letter country code>
      id_type: 'PASSPORT',
      id_number: 'G0000000',
      dob: '1992-12-07', # yyyy-mm-dd
      phone_number: '00000000000'
    }

    # Set the options for the job
    options = {
      signature: true
    }

    # Submit the job
    JSON.parse(connection.submit_job(partner_params(5), id_info, options))
  end

  # Public: Makes a request to verify the ID information of a user by comparing
  # the user's SmartSelfie to either the photo of the user on file in an ID authority
  # database or a photo of their ID card.
  #
  # Returns a verification result Hash
  def perform_biometric_kyc
    # Create image list
    # image_type_id: Integer
    # 0 - Selfie image jpg or png (if you have the full path of the selfie)
    # 2 - Selfie image jpg or png base64 encoded (if you have the base64image string of the selfie)
    # 4 - Liveness image jpg or png (if you have the full path of the liveness image)
    # 6 - Liveness image jpg or png base64 encoded (if you have the base64image string of the liveness image)
    image_details = [
      {
        image_type_id: 0,
        image: '/path/to/selfie_image.jpeg'
      },
      { # Not required if you don't require proof of life (note photo of photo check will still be performed on the uploaded selfie)
        image_type_id: 4,
        image: '/path/to/liveness_image.jpeg'
      }
    ]

    # Create ID number info
    id_info = {
      first_name: 'John',
      last_name: 'Doe',
      country: 'GH', # 2-letter country code>
      id_type: 'PASSPORT',
      id_number: 'G0000000',
      dob: '1992-12-07', # yyyy-mm-dd
      entered: 'true' # must be a string
    }

    # Submit the job
    web_api_connection.submit_job(partner_params(1), image_details, id_info, job_options)
  end

  # Public: Makes a request to verify the authenticity of Identity documents submitted by users and
  # confirm that the document actually belongs to the user by comparing the user's selfie to the
  # photo on the document.
  #
  # Returns a verification result Hash
  def perform_document_verification
    # Create image list
    # image_type_id: Integer
    # 0 - Selfie image jpg or png (if you have the full path of the selfie)
    # 2 - Selfie image jpg or png base64 encoded (if you have the base64image string of the selfie)
    # 4 - Liveness image jpg or png (if you have the full path of the liveness image)
    # 6 - Liveness image jpg or png base64 encoded (if you have the base64image string of the liveness image)
    # 1 - Front of ID document image jpg or png (if you have the full path of the selfie)
    # 3 - Front of ID document image jpg or png base64 encoded (if you have the base64image string of the selfie)
    # 5 - Back of ID document image jpg or png (if you have the full path of the selfie)
    # 7 - Back of ID document image jpg or png base64 encoded (if you have the base64image string of the selfie)
    image_details = [
      {
        image_type_id: 0,
        image: '/path/to/selfie_image.jpeg'
      },
      { # Not required if you don't require proof of life (note photo of photo check will still be performed on the uploaded selfie)
        image_type_id: 4,
        image: '/path/to/liveness_image.jpeg'
      },
      {
        image_type_id: 1,
        image: '/path/to/front_document_image.jpeg'
      },
      { # Optional, only use if you're uploading the back of the id document image
        image_type_id: 5,
        image: '/path/to/back_document_image.jpeg'
      }
    ]

    # The ID Document Information
    id_info = {
      country: 'GH', # The country where ID document was issued
      id_type: 'PASSPORT' # The ID document type
    }

    # Submit the job
    web_api_connection.submit_job(partner_params(6), image_details, id_info, job_options)
  end

  # Public: Makes a request to verify that an existing user is really the person attempting
  # to access your system or service. SmartSelfie Authentication can be used as part of a multi-factor
  # authentication system.
  #
  # Returns a verification result Hash
  def perform_smart_selfie_authentication
    # Create required tracking parameters
    partner_params = {
      user_id: '512c9c37-a689-4959-a620-bed75fb41344', # previously registered user's user_id
      job_id: SecureRandom.uuid, # new unique job ID
      job_type: 2
    }

    # Create image list
    # image_type_id: Integer
    # 0 - Selfie image jpg or png (if you have the full path of the selfie)
    # 2 - Selfie image jpg or png base64 encoded (if you have the base64image string of the selfie)
    # 4 - Liveness image jpg or png (if you have the full path of the liveness image)
    # 6 - Liveness image jpg or png base64 encoded (if you have the base64image string of the liveness image)
    image_details = [
      {
        image_type_id: 0,
        image: '/path/to/selfie_image.jpeg'
      },
      { # Not required if you don't require proof of life (note photo of photo check will still be performed on the uploaded selfie)
        image_type_id: 4,
        image: '/path/to/liveness_image.jpeg'
      }
    ]

    # Submit the job
    web_api_connection.submit_job(partner_params, image_details, nil, job_options)
  end

  private

  def partner_params(job_type)
    {
      user_id: user_id,
      job_id: job_id,
      job_type: job_type
    }
  end

  def web_api_connection
    return @web_api_connection if defined?(@web_api_connection)

    @web_api_connection = SmileIdentityCore::WebApi.new(partner_id, default_callback, api_key, sid_server)
  end

  def job_options
    {
      return_job_status: true, # Set to true if you want to get the job result in sync (in addition to the result been sent to your callback). If set to false, result is sent to callback url only.
      return_history: false, # Set to true to receive all of the updates you would otherwise have received in your callback as opposed to only the final result. You must set return_job_status to true to use this flag.
      return_image_links: true, # Set to true to receive links to the selfie and the photo it was compared to. You must set return_job_status to true to use this flag.
      signature: true
    }
  end
end

# Enhanced KYC
smart_bank = SmartBank.new
enhanced_kyc_response = smart_bank.perform_enhanced_kyc
enhanced_kyc_response['success'] # => true
enhanced_kyc_response['result']['PartnerParams']['job_id'] # job_id
enhanced_kyc_response['result']['PartnerParams']['user_id'] # user_id
enhanced_kyc_response['result']['PartnerParams']['job_type'] # => 5
# See https://docs.smileidentity.com/products/for-individuals-kyc/identity-lookup#return-values for the full JSON response interpretation

# Biometric KYC
bio_kyc_response = smart_bank.perform_biometric_kyc
bio_kyc_response['success'] # => true
bio_kyc_response['result']['PartnerParams']['job_id'] # job_id
bio_kyc_response['result']['PartnerParams']['user_id'] # user_id
bio_kyc_response['result']['PartnerParams']['job_type'] # => 1

# Document verification
doc_verification_response = smart_bank.perform_document_verification
doc_verification_response['success'] # => true
doc_verification_response['result']['PartnerParams']['job_id'] # job_id
doc_verification_response['result']['PartnerParams']['user_id'] # user_id
doc_verification_response['result']['PartnerParams']['job_type'] # => 6

# Smart Selfie Authentication
smart_selfie_auth_response = smart_bank.perform_smart_selfie_authentication
smart_selfie_auth_response['success'] # => true
smart_selfie_auth_response['result']['PartnerParams']['job_id'] # job_id
smart_selfie_auth_response['result']['PartnerParams']['user_id'] # user_id
smart_selfie_auth_response['result']['PartnerParams']['job_type'] # => 2

# All jobs submitted with a selfie has the same return values, result codes and texts. For example
# see https://docs.smileidentity.com/products/for-individuals-kyc/biometric-kyc#return-values.
# Save the returned user_id and job_id in your DB as you would need them later when you call other services.
