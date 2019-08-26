RSpec.describe SmileIdentityCore do
  let (:partner_id) {1}
  let (:rsa) { OpenSSL::PKey::RSA.new(1024) }
  let (:api_key) {Base64.strict_encode64(rsa.public_key.to_pem)}
  let (:connection) { SmileIdentityCore::Signature.new(partner_id, api_key)}

  it 'should return the defined keys' do
    payload = connection.generate_sec_key
    [:sec_key, :timestamp].each do |key|
      expect(payload).to have_key(key)
    end
  end

  it 'should correctly calculate the sec_key' do
    payload = connection.generate_sec_key
    sec_key = payload[:sec_key]
    encrypted, hashed = sec_key.split('|')

    timestamp = connection.instance_variable_get('@timestamp')
    signature = Digest::SHA256.hexdigest([partner_id, timestamp].join(":"))

    expect(hashed).to eq(signature)
    expect(rsa.private_decrypt(Base64.decode64(encrypted))).to eq(signature)
  end

end
