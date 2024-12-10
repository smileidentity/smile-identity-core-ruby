# frozen_string_literal: true

module SmileIdentityCore
  # Contains handy methods to generate and confirm signature for authentication
  class Signature
    def initialize(partner_id, api_key)
      @api_key = api_key
      @partner_id = partner_id
    end

    # Generates a signature based on the specified timestamp (uses the current time by default)
    #
    # @return [Hash] containing both the signature and related timestamp
    def generate_signature(timestamp = Time.now.to_s)
      get_signature(timestamp)
    end

    def generate_iso_timestamp_signature(timestamp = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%S.%LZ'))
      get_signature(timestamp)
    end

    # Confirms the signature against a newly generated signature based on the same timestamp
    #
    # @param [String] timestamp the timestamp to generate the signature from
    # @param [String] msg_signature a previously generated signature, to be confirmed
    # @return [Boolean] TRUE or FALSE
    def confirm_signature(timestamp, msg_signature)
      get_signature(timestamp)[:signature] == msg_signature
    end

    private

    def get_signature(timestamp)
      hmac = OpenSSL::HMAC.new(@api_key, 'sha256')
      hmac.update(timestamp.to_s)
      hmac.update(@partner_id)
      hmac.update('sid_request')
      @signature = Base64.strict_encode64(hmac.digest)
      {
        signature: @signature,
        timestamp: timestamp.to_s,
      }
    end
  end
end
