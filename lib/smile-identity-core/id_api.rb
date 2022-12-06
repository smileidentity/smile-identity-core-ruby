# frozen_string_literal: true

require_relative 'validations'

module SmileIdentityCore
  # Allows you to query the Identity Information for an individual using their ID number
  class IDApi
    include Validations

    REQUIRED_ID_INFO_FIELD = %i[country id_type id_number].freeze

    def initialize(partner_id, api_key, sid_server)
      @partner_id = partner_id.to_s
      @api_key = api_key

      @url = if sid_server !~ URI::DEFAULT_PARSER.make_regexp
               SmileIdentityCore::ENV::SID_SERVER_MAPPING[sid_server.to_s]
             else
               sid_server
             end
    end

    def submit_job(partner_params, id_info, options = {})
      @partner_params = validate_partner_params(symbolize_keys(partner_params))
      @id_info = validate_id_info(symbolize_keys(id_info), REQUIRED_ID_INFO_FIELD)

      unless [JobType::ENHANCED_KYC, JobType::BUSINESS_VERIFICATION].include?(@partner_params[:job_type].to_i)
        raise ArgumentError, 'Please ensure that you are setting your job_type to 5 or 7 to query ID Api'
      end

      if partner_params[:job_type] == JobType::BUSINESS_VERIFICATION
        return SmileIdentityCore::BusinessVerification
               .new(@partner_id, @api_key, @url)
               .submit_job(partner_params, id_info)
      end

      options = symbolize_keys(options || {})
      @use_async_endpoint = options.fetch(:async, false)

      setup_requests
    end

    private

    def symbolize_keys(params)
      params.is_a?(Hash) ? params.transform_keys(&:to_sym) : params
    end

    def setup_requests
      request = Typhoeus::Request.new(
        "#{@url}/#{endpoint}",
        method: 'POST',
        headers: { 'Content-Type' => 'application/json' },
        body: configure_json
      )

      request.on_complete do |response|
        return response.body if response.success?

        raise "#{response.code}: #{response.body}"
      end
      request.run
    end

    def endpoint
      @use_async_endpoint ? 'async_id_verification' : 'id_verification'
    end

    def configure_json
      signature_generator.generate_signature(Time.now.to_s)
                         .merge(@id_info)
                         .merge(
                           partner_id: @partner_id,
                           partner_params: @partner_params,
                           source_sdk: SmileIdentityCore::SOURCE_SDK,
                           source_sdk_version: SmileIdentityCore::VERSION
                         )
                         .to_json
    end

    def signature_generator
      SmileIdentityCore::Signature.new(@partner_id, @api_key)
    end
  end
end
