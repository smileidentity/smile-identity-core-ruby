module SmileIdentityCore
  class Utilities

    def initialize(partner_id, api_key, sid_server)
      @partner_id = partner_id.to_s
      @api_key = api_key

      if !(sid_server =~ URI::regexp)
        sid_server_mapping = {
          0 => 'https://3eydmgh10d.execute-api.us-west-2.amazonaws.com/test',
          1 => 'https://la7am6gdm8.execute-api.us-west-2.amazonaws.com/prod'
        }
        @url = sid_server_mapping[sid_server.to_i]
      else
        @url = sid_server
      end

      @signature_connection = SmileIdentityCore::Signature.new(@partner_id, @api_key)

    end

    def get_job_status(user_id, job_id, options = {})

      if(options.nil? || options.empty?)
        options = {
          return_history: false,
          return_job_status: false
        }
      end

      @timestamp = Time.now.to_i
      return query_job_status(user_id, job_id, symbolize_keys(options))
    end

    private

    def symbolize_keys params
      (params.is_a?(Hash)) ? Hash[params.map{ |k, v| [k.to_sym, v] }] : params
    end

    def query_job_status(user_id, job_id, options)
      url = "#{@url}/job_status"

      request = Typhoeus::Request.new(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        method: :post,
        body: configure_job_query(user_id, job_id, options)
      )

      request.on_complete do |response|
        begin
          body = JSON.parse(response.body)

          valid = @signature_connection.confirm_sec_key(body['timestamp'], body['signature'])

          if(!valid)
            raise "Unable to confirm validity of the job_status response"
          end

          return body
        rescue => e
          raise e
        end
      end

      request.run
    end

    def configure_job_query(user_id, job_id, options)
      return {
        sec_key: @signature_connection.generate_sec_key(@timestamp)[:sec_key],
        timestamp: @timestamp,
        user_id: user_id,
        job_id: job_id,
        partner_id: @partner_id,
        image_links: options[:return_image_links] || false,
        history:  options[:return_history] || false
      }.to_json
    end

  end
end
