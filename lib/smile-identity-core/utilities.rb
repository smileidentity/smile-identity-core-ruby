# frozen_string_literal: true

module SmileIdentityCore
  # A utility class to query job status
  class Utilities
    def initialize(partner_id, api_key, sid_server)
      @api_key = api_key
      @partner_id = partner_id.to_s
      @url = SmileIdentityCore::ENV.determine_url(sid_server)

      @signature_connection = SmileIdentityCore::Signature.new(@partner_id, @api_key)
    end

    def get_job_status(user_id, job_id, options = {})
      options = symbolize_keys(options || {})
      options[:return_history] ||= false
      options[:return_image_links] ||= false

      query_job_status(configure_job_query(user_id, job_id,
        options).merge(@signature_connection.generate_signature(Time.zone.now.to_s)))
    end

    private

    def symbolize_keys(params)
      params.is_a?(Hash) ? params.transform_keys(&:to_sym) : params
    end

    def query_job_status(request_json_data)
      request = Typhoeus::Request.new(
        "#{@url}/job_status",
        headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
        method: :post,
        body: request_json_data.to_json,
      )

      request.on_complete do |response|
        body = JSON.parse(response.body)

        # NB: we have to trust that the server will return the right kind of
        # timestamp (integer or string) for the signature, and the right kind
        # of signature in the "signature" field. The best way to know what
        # kind of validation to perform is by remembering which kind of
        # security we started with.
        valid = @signature_connection.confirm_signature(body['timestamp'], body['signature'])

        raise 'Unable to confirm validity of the job_status response' unless valid

        return body
      rescue StandardError => e
        raise e
      end

      request.run
    end

    def configure_job_query(user_id, job_id, options)
      {
        user_id: user_id,
        job_id: job_id,
        partner_id: @partner_id,
        image_links: options[:return_image_links],
        history: options[:return_history],
        source_sdk: SmileIdentityCore::SOURCE_SDK,
        source_sdk_version: SmileIdentityCore::VERSION,
      }
    end
  end
end
