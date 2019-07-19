module SmileIdentityCore
  class Signature

    def initialize(partner_id, api_key)
      @api_key = api_key
      @partner_id = partner_id.to_i
    end

    def generate_sec_key(timestamp=Time.now.to_i)
      @timestamp = timestamp

      hash_signature = Digest::SHA256.hexdigest([@partner_id, @timestamp].join(":"))
      public_key = OpenSSL::PKey::RSA.new(Base64.strict_decode64(@api_key))
      @sec_key = [Base64.strict_encode64(public_key.public_encrypt(hash_signature)), hash_signature].join('|')

      return {
        sec_key: @sec_key,
        timestamp: @timestamp
      }
  end
  end
end
