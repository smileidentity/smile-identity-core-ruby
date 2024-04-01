# frozen_string_literal: true

RSpec.describe SmileIdentityCore::Utilities do
  let(:partner_id) { 1 }
  let(:sid_server) { 0 }
  let(:rsa) { OpenSSL::PKey::RSA.new(1024) }
  let(:api_key) { Base64.encode64(rsa.public_key.to_pem) }
  let(:connection) { described_class.new(partner_id, api_key, sid_server) }

  describe '#initialize' do
    it 'sets the partner_id and api_key instance variables' do
      expect(connection.instance_variable_get(:@partner_id)).to eq(partner_id.to_s)
      expect(connection.instance_variable_get(:@api_key)).to eq(api_key)
    end

    it 'sets the correct @url instance variable' do
      expect(connection.instance_variable_get(:@url)).to eq('https://testapi.smileidentity.com/v1')

      connection = described_class.new(partner_id, api_key, 'https://something34.api.us-west-2.amazonaws.com/something')
      expect(connection.instance_variable_get(:@url)).to eq('https://something34.api.us-west-2.amazonaws.com/something')
    end
  end

  describe '#get_job_status' do
    let(:user_id) { rand(100_000) }
    let(:job_id) { rand(100_000) }
    let(:return_history) { [true, false].sample }
    let(:return_image_links) { [true, false].sample }

    it 'munges parameters and passes the request to #query_job_status' do
      # NB: testing by mocking what's passed to #query_job_status isn't ideal, because it makes
      # it harder to refactor the class' internals, but it'll have to do for now.

      allow(connection).to receive(:query_job_status).with(
        user_id: user_id,
        job_id: job_id,
        partner_id: partner_id.to_s, # NB the .to_s
        history: return_history,
        image_links: return_image_links,
        timestamp: /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [-+]\d{4}/, # new signature!
        signature: instance_of(String), # new signature!
        source_sdk: SmileIdentityCore::SOURCE_SDK,
        source_sdk_version: SmileIdentityCore::VERSION,
      )

      connection.get_job_status(
        user_id,
        job_id,
        { return_history: return_history, return_image_links: return_image_links },
      )
    end

    context 'when options are missing' do
      it 'sets default options when nothing is passed' do
        allow(connection).to receive(:query_job_status).with(hash_including(history: false, image_links: false))
        connection.get_job_status(user_id, job_id)
      end

      it 'sets default options when empty hash is passed' do
        allow(connection).to receive(:query_job_status).with(hash_including(history: false, image_links: false))
        connection.get_job_status(user_id, job_id, {})
      end
    end

    context 'when options are provided as strings' do
      it 'symbolizes them' do
        allow(connection).to receive(:query_job_status).with(
          hash_including(history: return_history, image_links: return_image_links),
        )
        connection.get_job_status(
          user_id, job_id, { 'return_history' => return_history, 'return_image_links' => return_image_links }
        )
      end
    end
  end

  describe '#query_job_status' do
    let(:url) { 'https://some_server.com/dev01' }
    let(:rsa) { OpenSSL::PKey::RSA.new(1024) }
    let(:partner_id) { 1 }
    let(:api_key) { Base64.encode64(rsa.public_key.to_pem) }
    let(:timestamp) { Time.now }
    let(:good_signature) do
      SmileIdentityCore::Signature.new(partner_id.to_s, api_key).generate_signature(timestamp.to_s)[:signature]
    end

    before do
      connection.instance_variable_set('@url', url)
      connection.instance_variable_set('@api_key', api_key)
      connection.instance_variable_set('@partner_id', partner_id)
    end

    def a_signed_response(signature:, timestamp:)
      {
        timestamp: timestamp, signature: signature, job_complete: true, job_success: false, code: '2302'
      }.to_json
    end

    it 'returns the response' do
      response_body = a_signed_response(signature: good_signature, timestamp: timestamp.to_s)
      typhoeus_response = Typhoeus::Response.new(code: 200, body: response_body)
      Typhoeus.stub(@url).and_return(typhoeus_response)

      expect(connection.send(:query_job_status, { some: 'json data' })).to eq(JSON.parse(response_body))
    end

    context 'when the signature is invalid' do
      it 'raises' do
        response_body = a_signed_response(signature: 'fake signature', timestamp: timestamp.to_s)
        typhoeus_response = Typhoeus::Response.new(code: 200, body: response_body)
        Typhoeus.stub(@url).and_return(typhoeus_response)

        expect do
          connection.send(:query_job_status, { some: 'json data' })
        end.to raise_error('Unable to confirm validity of the job_status response')
      end
    end
  end

  describe '#configure_job_query' do
    let(:partner_id) { 4242 }
    let(:return_history) { [true, false].sample }
    let(:return_image_links) { [true, false].sample }

    it 'sets the correct keys on the payload' do
      connection.instance_variable_set(:@timestamp, 'we only care here that it comes through')

      result = connection.send(:configure_job_query,
        111, 222, { return_history: return_history, return_image_links: return_image_links })

      expect(result[:user_id]).to eq(111)
      expect(result[:job_id]).to eq(222)
      expect(result[:partner_id]).to eq('4242') # NB: it gets .to_s'd
      expect(result[:history]).to eq(return_history)
      expect(result[:image_links]).to eq(return_image_links)
    end
  end
end
