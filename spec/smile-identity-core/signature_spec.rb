# frozen_string_literal: true

RSpec.describe SmileIdentityCore::Signature do
  let(:partner_id) { '001' }
  let(:rsa) { OpenSSL::PKey::RSA.new(1024) }
  let(:api_key) { Base64.encode64(rsa.public_key.to_pem) }
  let(:connection) { SmileIdentityCore::Signature.new(partner_id, api_key) }

  describe '#generate_signature' do
    it 'should return the defined keys' do
      payload = connection.generate_signature
      %i[signature timestamp].each do |key|
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
      hmac.update('sid_request')
      signature = Base64.strict_encode64(hmac.digest)
      expect(payload[:signature]).to eq(signature)
    end
  end

  describe '#confirm_signature' do
    it 'should confirm an incoming signature from the server' do
      timestamp = Time.now.to_s
      hmac = OpenSSL::HMAC.new(api_key, 'sha256')
      hmac.update(timestamp)
      hmac.update(partner_id)
      hmac.update('sid_request')
      signature = Base64.strict_encode64(hmac.digest)
      expect(connection.confirm_signature(timestamp, signature)).to eq(true)
    end
  end
end
