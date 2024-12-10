# frozen_string_literal: true

RSpec.describe SmileIdentityCore::AddressVerification do
  let(:partner_id) { '001' }
  let(:api_key) { Base64.encode64(OpenSSL::PKey::RSA.new(1024).public_key.to_pem) }
  let(:sid_server) { 0 }
  let(:connection) { described_class.new(partner_id, api_key, sid_server) }

  let(:payload) do
    {
      country: 'ZA',
      address: 'NEWLANDS WESTERN CAPE 007725',
      utility_number: '07101602642',
      utility_provider: 'IkejaElectric',
      id_number: '1234567890123',
      full_name: 'John Doe',
      callback_url: 'https://webhook.site/test',
    }
  end

  let(:address_verification_response) do
    {
      success: true,
    }.to_json
  end

  describe 'when initialized' do
    it 'sets the partner_id instance variables' do
      expect(connection.instance_variable_get(:@partner_id)).to eq(partner_id)
    end

    it 'sets the api_key instance variables' do
      expect(connection.instance_variable_get(:@api_key)).to eq(api_key)
    end

    it 'sets the sid_server instance variables' do
      expect(connection.instance_variable_get(:@sid_server)).to eq(sid_server)
    end

    it 'sets the correct @url instance variable' do
      expect(connection.instance_variable_get(:@url)).to eq('https://testapi.smileidentity.com/v1')
    end
  end

  context 'when the private methods behave correctly' do
    before do
      connection.instance_variable_set('@params', payload)
    end

    describe '#headers' do
      it 'generates correct headers' do
        signature_instance = SmileIdentityCore::Signature.new(partner_id, api_key)
        signature = { signature: Base64.strict_encode64('signature'), timestamp: Time.now.to_s }
        allow(signature_instance).to receive(:generate_iso_timestamp_signature).and_return(signature)
        allow(SmileIdentityCore::Signature).to receive(:new).and_return(signature_instance)

        headers = connection.send(:construct_and_validate_headers)
        expect(headers).to include(
          'smileid-source-sdk' => SmileIdentityCore::SOURCE_SDK,
          'smileid-source-sdk-version' => SmileIdentityCore::VERSION,
          'smileid-request-signature' => signature[:signature],
          'smileid-timestamp' => signature[:timestamp],
          'smileid-partner-id' => partner_id,
        )
      end
    end

    describe 'header construction' do
      it 'constructs headers with valid keys and values' do
        signature_instance = SmileIdentityCore::Signature.new(partner_id, api_key)
        signature = { signature: Base64.strict_encode64('signature'), timestamp: Time.now.utc.iso8601 }
        allow(signature_instance).to receive(:generate_iso_timestamp_signature).and_return(signature)
        allow(SmileIdentityCore::Signature).to receive(:new).and_return(signature_instance)

        headers = connection.send(:construct_and_validate_headers)
        expect(headers.keys).to match_array(%w[
          smileid-source-sdk smileid-source-sdk-version
          smileid-request-signature smileid-timestamp smileid-partner-id
        ])
        expect(headers['smileid-source-sdk']).to eq(SmileIdentityCore::SOURCE_SDK)
        expect(headers['smileid-source-sdk-version']).to eq(SmileIdentityCore::VERSION)
        expect(headers['smileid-request-signature']).to eq(signature[:signature])
      end
    end

    describe 'unsupported country codes' do
      before do
        response = Typhoeus::Response.new(
          code: 400,
          body: '{"code":"2413","error":"\"country\" must be one of [NG, ZA]","success":false}',
        )
        Typhoeus.stub("#{connection.instance_variable_get(:@url)}/async-verify-address").and_return(response)
      end

      it 'raises a runtime error for unsupported countries' do
        invalid_payload = payload.merge(country: 'DD')
        expect { connection.submit_job(invalid_payload) }
          .to raise_error(RuntimeError,
            /400:\s*{\s*"code":"2413",\s*"error":"\\"country\\" must be one of \[NG, ZA\]",\s*"success":false\s*}/)
      end
    end

    describe '#submit_job' do
      it 'submits the job' do
        allow(connection).to receive(:submit_job).and_return(address_verification_response)
        expect(connection.submit_job(payload)).to eq(address_verification_response)
      end
    end

    describe '#query_job_status' do
      it 'queries the job status' do
        allow(connection).to receive(:query_job_status).and_return(address_verification_response)
        expect(connection.query_job_status).to eq(address_verification_response)
      end
    end

    describe 'payload validation' do
      it 'raises an error when country is missing' do
        invalid_payload = payload.except(:country)
        expect { connection.submit_job(invalid_payload) }.to raise_error(RuntimeError)
      end

      it 'raises an error when address is missing' do
        invalid_payload = payload.except(:address)
        expect { connection.submit_job(invalid_payload) }.to raise_error(RuntimeError)
      end

      it 'raises an error when callback_url is missing' do
        invalid_payload = payload.except(:callback_url)
        expect { connection.submit_job(invalid_payload) }.to raise_error(RuntimeError)
      end

      context 'when the country is NG' do
        it 'raises an error when utility_number is missing' do
          invalid_payload = payload.except(:utility_number)
          expect { connection.submit_job(invalid_payload) }.to raise_error(RuntimeError)
        end

        it 'raises an error when utility_provider is missing' do
          invalid_payload = payload.except(:utility_provider)
          expect { connection.submit_job(invalid_payload) }.to raise_error(RuntimeError)
        end
      end

      context 'when the country is ZA' do
        it 'raises an error when id_number is missing' do
          za_payload = payload.merge(country: 'ZA').except(:utility_number, :utility_provider, :id_number)
          expect { connection.submit_job(za_payload) }.to raise_error(RuntimeError)
        end
      end
    end

    describe 'submitting address verification requests' do
      before do
        response = Typhoeus::Response.new(code: 200, body: address_verification_response)
        Typhoeus.stub("#{connection.instance_variable_get(:@url)}/async-verify-address").and_return(response)
      end

      it 'successfully sends the request with #submit_requests' do
        response = connection.send(:submit_requests)
        expect(JSON.parse(response)['success']).to be(true)
      end

      it 'successfully submits a job with #submit_job' do
        response = connection.submit_job(payload)
        expect(JSON.parse(response)['success']).to be(true)
      end
    end
  end
end
