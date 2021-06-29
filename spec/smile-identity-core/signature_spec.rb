RSpec.describe SmileIdentityCore::Signature do
  let (:partner_id) {'001'}
  let (:rsa) { OpenSSL::PKey::RSA.new(1024) }
  let (:api_key) {Base64.encode64(rsa.public_key.to_pem)}
  let (:connection) { SmileIdentityCore::Signature.new(partner_id, api_key)}

  describe '#generate_sec_key' do
    it 'should return the defined keys' do
      payload = connection.generate_sec_key
      [:sec_key, :timestamp].each do |key|
        expect(payload).to be_kind_of(Hash)
        expect(payload).to have_key(key)
      end
    end

    it 'should create a sec_key for the server' do
      payload = connection.generate_sec_key
      sec_key = payload[:sec_key]
      encrypted, hashed = sec_key.split('|')

      timestamp = connection.instance_variable_get('@timestamp')
      signature = Digest::SHA256.hexdigest([partner_id.to_i, timestamp].join(":"))

      expect(hashed).to eq(signature)
      expect(rsa.private_decrypt(Base64.decode64(encrypted))).to eq(signature)
    end
  end

  describe '#generate_signature' do
    it 'should return the defined keys' do
      payload = connection.generate_signature
      [:signature, :timestamp].each do |key|
        expect(payload).to be_kind_of(Hash)
        expect(payload).to have_key(key)
        expect(payload[key]).to be_kind_of(String)
      end
    end

    it 'should create a signature for the server' do
      payload = connection.generate_signature
      hmac = OpenSSL::HMAC.new(api_key, 'sha256')
      hmac.update(payload[:timestamp])
      hmac.update(partner_id)
      hmac.update("sid_request")
      signature = Base64.strict_encode64(hmac.digest())
      expect(payload[:signature]).to eq(signature)
    end
  end

  describe '#confirm_signature' do
    it 'should confirm an incoming signature from the server' do
      timestamp = Time.now.to_s
      hmac = OpenSSL::HMAC.new(api_key, 'sha256')
      hmac.update(timestamp)
      hmac.update(partner_id)
      hmac.update("sid_request")
      signature = Base64.strict_encode64(hmac.digest())
      expect(connection.confirm_signature(timestamp, signature)).to eq(true)
    end
  end

  describe '#confirm_sec_key' do
    it 'should confirm the sec_key from the server' do
      timestamp = Time.now.to_i
      hash_signature = Digest::SHA256.hexdigest([partner_id.to_i, timestamp].join(":"))
      sec_key = [Base64.encode64(rsa.private_encrypt(hash_signature)), hash_signature].join('|')

      expect(connection.confirm_sec_key(timestamp, sec_key)).to eq(true)
    end
  end
end
