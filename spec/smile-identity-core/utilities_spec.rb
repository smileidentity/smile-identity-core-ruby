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

  describe '#get_job_status' do
    let(:user_id) { rand(100000) }
    let(:job_id) { rand(100000) }
    let(:return_history) { [true, false].sample }
    let(:return_image_links) { [true, false].sample }

    it 'munges parameters and passes the request to #query_job_status' do
      # NB: testing by mocking what's passed to #query_job_status isn't ideal, because it makes
      # it harder to refactor the class' internals, but it'll have to do for now.

      expect(connection).to receive(:query_job_status).with(
        user_id: user_id,
        job_id: job_id,
        partner_id: partner_id.to_s, # NB the .to_s
        history: return_history,
        image_links: return_image_links,
        timestamp: /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [-+]\d{4}/, # new signature!
        signature: instance_of(String), # new signature!
        )

      connection.get_job_status(
        user_id,
        job_id,
        { return_history: return_history, return_image_links: return_image_links, use_legacy_sec_key: false })
    end

    context 'when options are missing' do
      it 'defaults them' do
        expect(connection).to receive(:query_job_status).with(hash_including(history: false, image_links: false))
        connection.get_job_status(user_id, job_id)

        expect(connection).to receive(:query_job_status).with(hash_including(history: false, image_links: false))
        connection.get_job_status(user_id, job_id, {})
      end
    end

    context 'when options are provided as strings' do
      it 'symbolizes them' do
        expect(connection).to receive(:query_job_status).with(
          hash_including(history: return_history, image_links: return_image_links))
        connection.get_job_status(
          user_id, job_id, { 'return_history' => return_history, 'return_image_links' => return_image_links })
      end
    end

    context 'when using the legacy sec_key' do
      context 'because it is defaulted' do
        it 'uses the legacy sec_key' do
          expect(connection).to receive(:query_job_status).with(hash_including(
            timestamp: instance_of(Integer), sec_key: instance_of(String)))
          connection.get_job_status(user_id, job_id)
        end
      end
      context 'because it is specified' do
        it 'uses the legacy sec_key' do
          expect(connection).to receive(:query_job_status).with(hash_including(
            timestamp: instance_of(Integer), sec_key: instance_of(String)))
          connection.get_job_status(user_id, job_id, use_legacy_sec_key: true)
        end
      end
    end
  end

  describe '#query_job_status' do
    let(:url) { 'https://some_server.com/dev01' }
    let(:rsa) { OpenSSL::PKey::RSA.new(1024) }
    let(:partner_id) { 1 }
    let(:api_key) { Base64.encode64(rsa.public_key.to_pem) }
    let(:timestamp) { Time.now }
    let(:good_sec_key) do
      hash_signature = Digest::SHA256.hexdigest([partner_id, timestamp.to_i].join(":"))
      [Base64.encode64(rsa.private_encrypt(hash_signature)), hash_signature].join('|')
    end
    let(:good_signature) do
      SmileIdentityCore::Signature.new(partner_id.to_s, api_key).generate_signature(timestamp.to_s)[:signature]
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
      response_body = a_signed_response(signature: good_signature, timestamp: timestamp.to_s)
      typhoeus_response = Typhoeus::Response.new(code: 200, body: response_body)
      Typhoeus.stub(@url).and_return(typhoeus_response)

      expect(connection.send(:query_job_status, { some: 'json data' })).to eq(JSON.load(response_body))
    end

    context 'for a legacy sec_key' do
      it 'returns the response' do
        response_body = a_signed_response(signature: good_sec_key, timestamp: timestamp.to_i)
        typhoeus_response = Typhoeus::Response.new(code: 200, body: response_body)
        Typhoeus.stub(@url).and_return(typhoeus_response)

        expect(connection.send(:query_job_status, { some: 'json data', sec_key: 'present' }))
          .to eq(JSON.load(response_body))
      end
    end

    context 'when the signature is invalid' do
      it 'raises' do
        response_body = a_signed_response(signature: "fake signature", timestamp: timestamp.to_s)
        typhoeus_response = Typhoeus::Response.new(code: 200, body: response_body)
        Typhoeus.stub(@url).and_return(typhoeus_response)

        expect {
          connection.send(:query_job_status, { some: 'json data' })
        }.to raise_error('Unable to confirm validity of the job_status response')
      end
    end
  end

  describe '#request_security' do
    let(:request_time) { Time.now }
    context 'for a legacy sec_key' do
      it 'should give a sec_key and timestamp' do
        expect_any_instance_of(SmileIdentityCore::Signature).to receive(:generate_sec_key) do
          { sec_key: 'a sec key', timestamp: request_time.to_i }
        end

        expect(connection.send(:request_security, request_time, use_legacy_sec_key: true))
          .to eq(sec_key: 'a sec key', timestamp: request_time.to_i)

        expect(connection.instance_variable_get(:@timestamp)).to eq(request_time.to_i)
        # is that crucial? not sure
      end
    end
    context 'for a newer signature' do
      it 'should give a signature and timestamp' do
        expect_any_instance_of(SmileIdentityCore::Signature).to receive(:generate_signature) do
          { signature: 'a signature', timestamp: request_time.to_s }
        end

        expect(connection.send(:request_security, request_time, use_legacy_sec_key: false))
          .to eq(signature: 'a signature', timestamp: request_time.to_s)

        expect(connection.instance_variable_get(:@timestamp)).to eq(request_time.to_s)
        # is that crucial? not sure
      end
    end
  end

  describe '#job_status_request' do
    let(:partner_id) { 4242 }
    let(:return_history) { [true, false].sample }
    let(:return_image_links) { [true, false].sample }

    it 'should set the correct keys on the payload' do
      connection.instance_variable_set(:@timestamp, "we only care here that it comes through")

      result = connection.send(:job_status_request,
        111, 222, { return_history: return_history, return_image_links: return_image_links })

      expect(result[:user_id]).to eq(111)
      expect(result[:job_id]).to eq(222)
      expect(result[:partner_id]).to eq('4242') # NB: it gets .to_s'd
      expect(result[:history]).to eq(return_history)
      expect(result[:image_links]).to eq(return_image_links)
    end
  end
end
