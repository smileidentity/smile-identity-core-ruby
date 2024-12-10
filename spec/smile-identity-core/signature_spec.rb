# frozen_string_literal: true

RSpec.describe SmileIdentityCore::Signature do
  let(:partner_id) { '001' }
  let(:rsa) { OpenSSL::PKey::RSA.new(1024) }
  let(:api_key) { Base64.encode64(rsa.public_key.to_pem) }
  let(:connection) { described_class.new(partner_id, api_key) }

  describe '#generate_signature' do
    it 'returns the defined keys with a non-ISO timestamp' do
      payload = connection.generate_signature
      %i[signature timestamp].each do |key|
        expect(payload).to be_a(Hash)
        expect(payload).to have_key(key)
        expect(payload[key]).to be_a(String)
      end
      expect(payload[:timestamp]).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/) # Non-ISO format
    end

    it 'creates a signature for the server with a non-ISO timestamp' do
      payload = connection.generate_signature
      hmac = OpenSSL::HMAC.new(api_key, 'sha256')
      hmac.update(payload[:timestamp])
      hmac.update(partner_id)
      hmac.update('sid_request')
      signature = Base64.strict_encode64(hmac.digest)
      expect(payload[:signature]).to eq(signature)
    end
  end

  describe '#generate_iso_timestamp_signature' do
    it 'returns the defined keys with an ISO timestamp' do
      payload = connection.generate_iso_timestamp_signature
      %i[signature timestamp].each do |key|
        expect(payload).to be_a(Hash)
        expect(payload).to have_key(key)
        expect(payload[key]).to be_a(String)
      end
      expect(payload[:timestamp]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z/) # ISO 8601 format
    end

    it 'creates a signature for the server with an ISO timestamp' do
      payload = connection.generate_iso_timestamp_signature
      hmac = OpenSSL::HMAC.new(api_key, 'sha256')
      hmac.update(payload[:timestamp])
      hmac.update(partner_id)
      hmac.update('sid_request')
      signature = Base64.strict_encode64(hmac.digest)
      expect(payload[:signature]).to eq(signature)
    end
  end

  describe '#confirm_signature' do
    it 'confirms an incoming signature from the server with a non-ISO timestamp' do
      timestamp = Time.now.to_s
      hmac = OpenSSL::HMAC.new(api_key, 'sha256')
      hmac.update(timestamp)
      hmac.update(partner_id)
      hmac.update('sid_request')
      signature = Base64.strict_encode64(hmac.digest)
      expect(connection.confirm_signature(timestamp, signature)).to be(true)
    end

    it 'confirms an incoming signature from the server with an ISO timestamp' do
      timestamp = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%S.%LZ')
      hmac = OpenSSL::HMAC.new(api_key, 'sha256')
      hmac.update(timestamp)
      hmac.update(partner_id)
      hmac.update('sid_request')
      signature = Base64.strict_encode64(hmac.digest)
      expect(connection.confirm_signature(timestamp, signature)).to be(true)
    end
  end
end
