# frozen_string_literal: true

module SmileIdentityCore
  class IDApi
    def initialize(partner_id, api_key, sid_server)
      @partner_id = partner_id.to_s
      @api_key = api_key

      @url = if sid_server !~ URI::DEFAULT_PARSER.make_regexp
               SmileIdentityCore::SID_SERVER_MAPPING[sid_server.to_s]
             else
               sid_server
             end
    end

    def submit_job(partner_params, id_info, options = {})
      self.partner_params = symbolize_keys partner_params
      self.id_info = symbolize_keys id_info
      options = symbolize_keys(options || {})
      @use_new_signature = options.fetch(:signature, false)
      @use_async_endpoint = options.fetch(:async, false)

      if @partner_params[:job_type].to_i != 5
        raise ArgumentError, 'Please ensure that you are setting your job_type to 5 to query ID Api'
      end

      setup_requests
    end

    def partner_params=(partner_params)
      raise ArgumentError, 'Please ensure that you send through partner params' if partner_params.nil?

      raise ArgumentError, 'Partner params needs to be a hash' unless partner_params.is_a?(Hash)

      %i[user_id job_id job_type].each do |key|
        next if partner_params[key] && !partner_params[key].nil? && !(if partner_params[key].is_a?(String)
                                                                        partner_params[key].empty?
                                                                      end)

        raise ArgumentError, "Please make sure that #{key} is included in the partner params"
      end

      @partner_params = partner_params
    end

    def id_info=(id_info)
      updated_id_info = id_info

      if updated_id_info.nil? || updated_id_info.keys.length.zero?
        raise ArgumentError, 'Please make sure that id_info not empty or nil'
      end

      %i[country id_type id_number].each do |key|
        unless updated_id_info[key] && !updated_id_info[key].nil? && !updated_id_info[key].empty?
          raise ArgumentError, "Please make sure that #{key} is included in the id_info"
        end
      end

      @id_info = updated_id_info
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
