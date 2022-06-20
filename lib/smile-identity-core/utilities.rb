module SmileIdentityCore
  class Utilities

    def initialize(partner_id, api_key, sid_server)
      @partner_id = partner_id.to_s
      @api_key = api_key

      if !(sid_server =~ URI::regexp)
        sid_server_mapping = {
          0 => 'https://testapi.smileidentity.com/v1',
          1 => 'https://api.smileidentity.com/v1',
        }
        @url = sid_server_mapping[sid_server.to_i]
      else
        @url = sid_server
      end

      @signature_connection = SmileIdentityCore::Signature.new(@partner_id, @api_key)

    end

    def get_job_status(user_id, job_id, options = {})
      options = symbolize_keys(options || {})
      options[:return_history] ||= false
      options[:return_image_links] ||= false

      query_job_status(configure_job_query(user_id, job_id, options).merge(request_security))
    end

    private

    def symbolize_keys params
      (params.is_a?(Hash)) ? Hash[params.map{ |k, v| [k.to_sym, v] }] : params
    end

    def query_job_status(request_json_data)
      url = "#{@url}/job_status"

      request = Typhoeus::Request.new(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        method: :post,
        body: request_json_data.to_json
      )

      request.on_complete do |response|
        begin
          body = JSON.parse(response.body)

          # NB: we have to trust that the server will return the right kind of
          # timestamp (integer or string) for the signature, and the right kind
          # of signature in the "signature" field. The best way to know what
          # kind of validation to perform is by remembering which kind of
          # security we started with.
          valid = @signature_connection.confirm_signature(body['timestamp'], body['signature'])

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

    def request_security
      @timestamp = Time.now.to_s
      {
        signature: @signature_connection.generate_signature(@timestamp)[:signature],
        timestamp: @timestamp,
      }
    end

    def configure_job_query(user_id, job_id, options)
      {
        user_id: user_id,
        job_id: job_id,
        partner_id: @partner_id,
        image_links: options[:return_image_links],
        history:  options[:return_history],
        source_sdk: SmileIdentityCore::SOURCE_SDK,
        source_sdk_version: SmileIdentityCore::VERSION
      }
    end
  end
end
