module SmileIdentityCore
  class IDApi

    def initialize(partner_id, api_key, sid_server)
      @partner_id = partner_id.to_s
      @api_key = api_key

      @sid_server = sid_server
      if !(sid_server =~ URI::regexp)
        sid_server_mapping = {
          0 => 'https://testapi.smileidentity.com/v1',
          1 => 'https://api.smileidentity.com/v1',
        }
        @url = sid_server_mapping[sid_server.to_i]
      else
        @url = sid_server
      end
    end

    def submit_job(partner_params, id_info, options = {})
      self.partner_params = symbolize_keys partner_params
      self.id_info = symbolize_keys id_info
      @use_new_signature = symbolize_keys(options || {}).fetch(:signature, false)

      if @partner_params[:job_type].to_i != 5
        raise ArgumentError.new('Please ensure that you are setting your job_type to 5 to query ID Api')
      end

      return setup_requests
    end

    def partner_params=(partner_params)
      if partner_params == nil
        raise ArgumentError.new('Please ensure that you send through partner params')
      end

      if !partner_params.is_a?(Hash)
        raise ArgumentError.new('Partner params needs to be a hash')
      end

      [:user_id, :job_id, :job_type].each do |key|
        unless partner_params[key] && !partner_params[key].nil? && !(partner_params[key].empty? if partner_params[key].is_a?(String))
          raise ArgumentError.new("Please make sure that #{key.to_s} is included in the partner params")
        end
      end

      @partner_params = partner_params
    end

    def id_info=(id_info)

      updated_id_info = id_info

      if updated_id_info.nil? ||  updated_id_info.keys.length == 0
        raise ArgumentError.new("Please make sure that id_info not empty or nil")
      end

      [:country, :id_type, :id_number].each do |key|
        unless updated_id_info[key] && !updated_id_info[key].nil? && !updated_id_info[key].empty?
          raise ArgumentError.new("Please make sure that #{key.to_s} is included in the id_info")
        end
      end

      @id_info = updated_id_info
    end

    private

    def symbolize_keys params
      (params.is_a?(Hash)) ? Hash[params.map{ |k, v| [k.to_sym, v] }] : params
    end

    def setup_requests
      url = "#{@url}/id_verification"

      request = Typhoeus::Request.new(
        url,
        method: 'POST',
        headers: {'Content-Type'=> "application/json"},
        body: configure_json
      )

      request.on_complete do |response|
        if response.success?
          return response.body
        elsif response.timed_out?
          raise "#{response.code.to_s}: #{response.body}"
        elsif response.code == 0
          # Could not get an http response, something's wrong.
          raise "#{response.code.to_s}: #{response.body}"
        else
          # Received a non-successful http response.
          raise "#{response.code.to_s}: #{response.body}"
        end
      end
      request.run
    end

    def configure_json
      request_security(use_new_signature: @use_new_signature)
        .merge(@id_info)
        .merge(
          partner_id: @partner_id,
          partner_params: @partner_params)
        .to_json
    end

    def request_security(use_new_signature: true)
      if use_new_signature
        @timestamp = Time.now.to_s
        {
          signature: SmileIdentityCore::Signature.new(@partner_id, @api_key).generate_signature(@timestamp)[:signature],
          timestamp: @timestamp,
        }
      else
        @timestamp = Time.now.to_i
        {
          sec_key: SmileIdentityCore::Signature.new(@partner_id, @api_key).generate_sec_key(@timestamp)[:sec_key],
          timestamp: @timestamp,
        }
      end
    end
  end
end
