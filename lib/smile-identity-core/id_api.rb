module SmileIdentityCore
  class IDApi

    def initialize(partner_id, api_key, sid_server)
      @partner_id = partner_id.to_s
      @api_key = api_key

      @sid_server = sid_server
      if !(sid_server =~ URI::regexp)
        sid_server_mapping = {
          0 => 'https://3eydmgh10d.execute-api.us-west-2.amazonaws.com/test',
          1 => 'https://la7am6gdm8.execute-api.us-west-2.amazonaws.com/prod'
        }
        @url = sid_server_mapping[sid_server.to_i]
      else
        @url = sid_server
      end
    end

    def submit_job(partner_params, id_info)
      self.partner_params = symbolize_keys partner_params

      @timestamp = Time.now.to_i

      self.id_info = symbolize_keys id_info

      # if its not a job type 5 then throw an error

      return setup_requests
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
      body = {
        timestamp: @timestamp,
        sec_key: determine_sec_key,
        partner_id: @partner_id,
        partner_params: @partner_params
      }

      body.merge!(@id_info)
      JSON.generate(body)
    end

  end
end
