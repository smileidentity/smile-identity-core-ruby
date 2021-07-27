RSpec.describe SmileIdentityCore::Utilities do
  let (:partner_id) {1}
  let (:sid_server) {0}
  let (:rsa) { OpenSSL::PKey::RSA.new(1024) }
  let (:api_key) {Base64.encode64(rsa.public_key.to_pem)}
  let (:connection) { SmileIdentityCore::Utilities.new(partner_id, api_key, sid_server)}

  describe '#initialize' do
    it "sets the partner_id and api_key instance variables" do
      expect(connection.instance_variable_get(:@partner_id)).to eq(partner_id.to_s)
      expect(connection.instance_variable_get(:@api_key)).to eq(api_key)
    end

    it "sets the correct @url instance variable" do
      expect(connection.instance_variable_get(:@url)).to eq('https://3eydmgh10d.execute-api.us-west-2.amazonaws.com/test')

      connection = SmileIdentityCore::Utilities.new(partner_id, api_key, 'https://something34.api.us-west-2.amazonaws.com/something')
      expect(connection.instance_variable_get(:@url)).to eq('https://something34.api.us-west-2.amazonaws.com/something')
    end
  end

  describe '#query_job_status' do
    let(:url) { 'https://some_server.com/dev01' }
    let(:rsa) { OpenSSL::PKey::RSA.new(1024) }
    let(:partner_id) { 1 }
    let(:api_key) { Base64.encode64(rsa.public_key.to_pem) }
    let(:timestamp) { Time.now.to_i }
    let(:good_sec_key) do
      hash_signature = Digest::SHA256.hexdigest([partner_id, timestamp].join(":"))
      [Base64.encode64(rsa.private_encrypt(hash_signature)), hash_signature].join('|')
    end

    before(:each) {
      connection.instance_variable_set('@url', url )
      connection.instance_variable_set('@api_key', api_key)
      connection.instance_variable_set('@partner_id', partner_id)
    }

    def a_signed_response(signature:, timestamp:)
      {
        timestamp: timestamp, signature: signature, job_complete: true, job_success: false, code: "2302"
      }.to_json
    end

    it 'returns the response' do
      response_body = a_signed_response(signature: good_sec_key, timestamp: timestamp)
      typhoeus_response = Typhoeus::Response.new(code: 200, body: response_body)
      Typhoeus.stub(@url).and_return(typhoeus_response)

      expect(connection.send(:query_job_status, '1', '1', {return_job_status: true, return_image_links: true}))
        .to eq(JSON.load(response_body))
    end

    context 'when the signature is invalid' do
      it 'raises' do
        response_body = a_signed_response(signature: "fake signature", timestamp: timestamp)
        typhoeus_response = Typhoeus::Response.new(code: 200, body: response_body)
        Typhoeus.stub(@url).and_return(typhoeus_response)

        expect {
          connection.send(:query_job_status, '1', '1', {return_job_status: true, return_image_links: true})
        }.to raise_error(OpenSSL::PKey::RSAError)
        # The specific error here matters less than the fact that it will raise.
        # The code tries to raise a custom error, but we don't currently handle it properly.
        # Leaving it this way for now, in case clients have come to rely on this behavior.
      end
    end
  end

  describe '#configure_job_query' do
    it 'should set the correct keys on the payload' do
      ['sec_key', 'timestamp', 'user_id', 'job_id', 'partner_id', 'image_links', 'history'].each do |key|
        expect(JSON.parse(connection.send(:configure_job_query, 1, 2, {return_history: true, return_image_links: true}))).to have_key(key)
      end
    end
  end

end
