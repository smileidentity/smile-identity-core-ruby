# frozen_string_literal: true

require 'json'
require 'base64'
require 'openssl'
require 'uri'
require 'typhoeus'
require_relative 'validations'

module SmileIdentityCore
  ##
  # The business verification product lets you search the business registration or
  # tax information (available in Nigeria only) of a business from one of our supported countries.
  # For more info visit https://docs.smileidentity.com/products/for-businesses-kyb/business-verification
  class BusinessVerification
    include Validations

    BASIC_BUSINESS_REGISTRATION = 'BASIC_BUSINESS_REGISTRATION'
    BUSINESS_REGISTRATION = 'BUSINESS_REGISTRATION'
    TAX_INFORMATION = 'TAX_INFORMATION'

    REQUIRED_ID_INFO_FIELD = %i[country id_type id_number].freeze

    ###
    # Submit business verification
    # @param [Hash] partner_params the options to create a message with.
    # @option opts [String] :job_type The job type, this should be 7
    # @option opts [String] :job_id A unique value generated by you to track jobs on your end.
    # @option opts [String] :user_id A unique value generated by you.
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

    # Submit business verification
    # @param [Hash] partner_params the options to create a job with.
    # @option opts [String] :job_type The job type, this should be 7
    # @option opts [String] :job_id A unique value generated by you to track jobs on your end.
    # @option opts [String] :user_id A unique value generated by you.
    # @param [Hash] id_info
    # @option opts [String] :country The job type, this should be 7
    # @option opts [String] :id_type A unique value generated by you to track jobs on your end.
    # @option opts [String] :id_number A unique value generated by you.
    # @option opts [String] :business_type The business incorporation type
    # bn - business name co - private/public limited it - incorporated trustees
    def submit_job(partner_params, id_info)
      @partner_params = validate_partner_params(symbolize_keys(partner_params))
      @id_info = validate_id_info(symbolize_keys(id_info), REQUIRED_ID_INFO_FIELD)

      if @partner_params[:job_type] != 7
        raise ArgumentError, 'Please ensure that you are setting your job_type to 7 to query Business Verification'
      end

      submit_requests
    end

    private

    def symbolize_keys(params)
      params.is_a?(Hash) ? params.transform_keys(&:to_sym) : params
    end

    def build_payload
      @payload = generate_signature
      @payload.merge!(@id_info)
      add_partner_info
      add_sdk_info
      @payload
    end

    def add_partner_info
      @payload[:partner_id] = @partner_id
      @payload[:partner_params] = @partner_params
    end

    def add_sdk_info
      @payload[:source_sdk] = SmileIdentityCore::SOURCE_SDK
      @payload[:source_sdk_version] = SmileIdentityCore::VERSION
    end

    def generate_signature
      SmileIdentityCore::Signature.new(@partner_id, @api_key).generate_signature
    end

    def submit_requests
      request = Typhoeus::Request.new(
        "#{@url}/business_verification",
        method: 'POST',
        headers: { 'Content-Type' => 'application/json' },
        body: build_payload.to_json
      )

      request.on_complete do |response|
        return response.body if response.success?

        raise "#{response.code}: #{response.body}"
      end
      request.run
    end

    alias setup_requests submit_requests
  end
end
