# frozen_string_literal: true

require 'json'
require 'typhoeus'
require_relative 'validations'

module SmileIdentityCore
  ##
  # The AML Check product allows you to perform due diligence on your customers by screening them against
  # global watchlists, politically exposed persons lists, and adverse media publications.
  # For more info visit https://docs.smileidentity.com/products/for-individuals-kyc/aml-check
  class AmlCheck
    include Validations

    ###
    # Submit AML
    # @param [String] :partner_id A unique number assigned by Smile ID to your account. Can be found in the portal
    # @param [String] :api_key your API key from the Smile Identity portal
    # @param [String] :sid_server Use 0 for the sandbox server, use 1 for production server
    def initialize(partner_id, api_key, sid_server)
      @partner_id = partner_id.to_s
      @api_key = api_key
      @sid_server = sid_server
      @url = if sid_server !~ URI::DEFAULT_PARSER.make_regexp
               SmileIdentityCore::ENV::SID_SERVER_MAPPING[sid_server.to_s]
             else
               sid_server
             end
    end

    # Submit AML
    # @param [Hash] params the options to create a job with.
    # @option opts [String] :job_id A unique value generated by you to track jobs on your end.
    # @option opts [String] :user_id A unique value generated by you.
    # @option opts [String] :full_name The full name of the customer.
    # @option opts [String] :birth_year The customer’s year of birth, in the format yyyy
    # @option opts [Array] :countries An array that takes the customer’s known nationalities in 2-character
    # (ISO 3166-1 alpha-2) format e.g. Nigeria is NG, Kenya is KE, etc
    # @option opts [boolean] :search_existing_user If you intend to re-use the name and year of birth
    # of a user’s previous KYC job
    # @option opts [Hash] :optional_info Any optional data, this will be returned
    # in partner_params.
    def submit_job(params)
      @params = symbolize_keys(params)
      @optional_info = @params['optional_info']
      submit_requests
    end

    private

    def symbolize_keys(params)
      params.is_a?(Hash) ? params.transform_keys(&:to_sym) : params
    end

    def build_payload
      @payload = generate_signature
      @payload.merge!(@params)
      add_partner_info
      add_sdk_info
      @payload
    end

    def add_partner_info
      @payload[:partner_id] = @partner_id
      @payload[:job_type] = SmileIdentityCore::JobType::AML
      @payload[:partner_params] = @optional_info if @optional_info
    end

    def add_sdk_info
      @payload[:source_sdk] = SmileIdentityCore::SOURCE_SDK
      @payload[:source_sdk_version] = SmileIdentityCore::VERSION
    end

    def generate_signature
      SmileIdentityCore::Signature.new(@partner_id, @api_key).generate_signature
    end

    def submit_requests
      request = Typhoeus::Request.new("#{@url}/aml", method: 'POST',
                                                     headers: { 'Content-Type' => 'application/json' },
                                                     body: build_payload.to_json)

      request.on_complete do |response|
        return response.body if response.success?

        raise "#{response.code}: #{response.body}"
      end
      request.run
    end

    alias setup_requests submit_requests
  end
end
