# frozen_string_literal: true

require 'json'
require 'typhoeus'
require_relative 'validations'

module SmileIdentityCore
  ##
  # The Address Verification Service allows you to verify address details provided by a user,
  # by comparing the address details provided by the user to the address details on file with the authorities database.
  # For more info visit https://docs.usesmileid.com/
  class AddressVerification
    include Validations

    ###
    # Initialize Address Verification
    # @param [String] :partner_id A unique number assigned by Smile ID to your account. Can be found in the portal
    # @param [String] :api_key Your API key from the Smile Identity portal
    # @param [String] :sid_server Use 0 for the sandbox server, use 1 for production server
    def initialize(partner_id, api_key, sid_server)
      @api_key = api_key
      @partner_id = partner_id.to_s
      @sid_server = sid_server
      @url = SmileIdentityCore::ENV.determine_url(sid_server)
    end

    ###
    # Submit Address Verification
    # @param [Hash] params the options to create a job with.
    # @option params [String] :country (required) The user's country (e.g., NG or ZA).
    # @option params [String] :address (required) The user's address.
    # @option params [String] :utility_number (required for NG) The utility account number.
    # @option params [String] :utility_provider (required for NG) The utility provider.
    # @option params [String] :id_number (required for ZA) The national ID number.
    # @option params [String] :full_name (optional) The user's full name.
    # @option params [String] :callback_url (required) The callback URL.
    def submit_job(params)
      @params = symbolize_keys(params)
      submit_requests
    end

    private

    def symbolize_keys(params)
      params.is_a?(Hash) ? params.transform_keys(&:to_sym) : params
    end

    def generate_signature
      SmileIdentityCore::Signature.new(@partner_id, @api_key).generate_signature
    end

    def construct_and_validate_headers
      signature = generate_signature
      {
        'smileid-source-sdk' => SmileIdentityCore::SOURCE_SDK,
        'smileid-source-sdk-version' => SmileIdentityCore::VERSION,
        'smileid-request-signature' => signature[:signature],
        'smileid-timestamp' => signature[:timestamp],
        'smileid-partner-id' => @partner_id,
      }
    end

    def submit_requests
      # Construct headers and body
      headers = construct_and_validate_headers
      body = @params.to_json

      # Create and run the request
      request = Typhoeus::Request.new("#{@url}/async-verify-address", method: 'POST',
        headers: headers,
        body: body)

      # Handle the response
      request.on_complete do |response|
        raise " #{response.code}: #{response.body}" unless response.success?

        return { success: true }.to_json
      end

      request.run
    end
  end
end
