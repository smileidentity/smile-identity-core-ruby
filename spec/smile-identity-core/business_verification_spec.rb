# frozen_string_literal: true

RSpec.describe SmileIdentityCore::BusinessVerification do
  let(:partner_id) { '001' }
  let(:api_key) { Base64.encode64(OpenSSL::PKey::RSA.new(1024).public_key.to_pem) }
  let(:sid_server) { 0 }
  let(:connection) { described_class.new(partner_id, api_key, sid_server) }

  let(:payload) do
    {
      partner_params: {
        user_id: 'kyb_test_user_008',
        job_id: 'DeXyJOGtaACFFfbZ2kxjuICE',
        job_type: SmileIdentityCore::JobType::BUSINESS_VERIFICATION
      },
      id_info: {
        country: 'NG',
        id_type: 'BUSINESS_REGISTRATION',
        id_number: 'A000000',
        business_type: 'co'
      }
    }
  end

  it 'sets REQUIRED_ID_INFO_FIELD' do
    expect(SmileIdentityCore::BusinessVerification::REQUIRED_ID_INFO_FIELD).to eq(%i[country id_type id_number])
  end

  describe 'when id_type is called' do
    it 'returns BASIC_BUSINESS_REGISTRATION' do
      expect(SmileIdentityCore::BusinessVerification::BASIC_BUSINESS_REGISTRATION).to eq('BASIC_BUSINESS_REGISTRATION')
    end

    it 'returns BUSINESS_REGISTRATION' do
      expect(SmileIdentityCore::BusinessVerification::BUSINESS_REGISTRATION).to eq('BUSINESS_REGISTRATION')
    end

    it 'returns TAX_INFORMATION' do
      expect(SmileIdentityCore::BusinessVerification::TAX_INFORMATION).to eq('TAX_INFORMATION')
    end
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

  context 'when #submit is called' do
    it 'throws ArgumentError when the partner_params is nil' do
      no_partner_parameters = nil
      expect { connection.submit_job(no_partner_parameters, payload[:id_info]) }
        .to raise_error(ArgumentError, 'Please ensure that you send through partner params')
    end

    it 'throws ArgumentError when the partner_params is an array' do
      array_partner_params = []
      expect { connection.submit_job(array_partner_params, payload[:id_info]) }
        .to raise_error(ArgumentError, 'Partner params needs to be a hash')
    end

    it 'throws ArgumentError when job_type is missing in the partner_params' do
      expect { connection.submit_job(payload[:partner_params].merge(job_type: nil), payload[:id_info]) }
        .to raise_error(ArgumentError, 'Please make sure that job_type is included in the partner params')
    end

    it 'throws ArgumentError when the job type is not 7' do
      expect do
        connection.submit_job(payload[:partner_params].merge(job_type: 1), payload[:id_info])
      end.to raise_error(ArgumentError,
                         'Please ensure that you are setting your job_type to 7 to query Business Verification')
    end

    it 'throws ArgumentError if id_info is nil' do
      expect { connection.submit_job(payload[:partner_params], nil) }
        .to raise_error(ArgumentError, 'Please make sure that id_info is not empty or nil')
    end

    it 'throws ArgumentError if id_info is empty' do
      expect { connection.submit_job(payload[:partner_params], {}) }
        .to raise_error(ArgumentError, 'Please make sure that id_info is not empty or nil')
    end

    it 'throws ArgumentError if either country id_type id_number is empty' do
      %i[country id_type id_number].each do |key|
        expect { connection.submit_job(payload[:partner_params], payload[:id_info].merge(key => '')) }
          .to raise_error(ArgumentError, "Please make sure that #{key} is included in the id_info")
      end
    end
  end

  context 'when the private methods behave correctly' do
    before do
      connection.instance_variable_set('@payload', {})
      connection.instance_variable_set('@id_info', payload[:id_info])
      connection.instance_variable_set('@partner_params', payload[:partner_params])
    end

    it 'sets source_sdk in the payload' do
      connection.send(:add_sdk_info)
      expect(connection.instance_variable_get('@payload')[:source_sdk]).to eq(SmileIdentityCore::SOURCE_SDK)
    end

    it 'sets source_sdk_version in the payload' do
      connection.send(:add_sdk_info)
      expect(connection.instance_variable_get('@payload')[:source_sdk_version]).to eq(SmileIdentityCore::VERSION)
    end

    describe '#setup_requests' do
      it 'returns a correct json object if it runs successfully' do
        body = {
          'signature': '---',
          'timestamp': '2022-10-17T10:46:49.392Z',
          'JSONVersion': '1.0.0',
          'SmileJobID': '0000001927',
          'PartnerParams': {
            'user_id': 'kyb_test_user_008',
            'job_id': 'DeXyJOGtaACFFfbZ2kxjuICE',
            'job_type': 7
          },
          'ResultType': 'Business Verification',
          'ResultText': 'Business Verified',
          'ResultCode': '1012',
          'IsFinalResult': 'true',
          'Actions': {
            'Verify_Business': 'Verified',
            'Return_Business_Info': 'Returned'
          },
          'company_information': {
            'company_type': 'PRIVATE_COMPANY_LIMITED_BY_SHARES',
            'country': 'Nigeria',
            'address': '10, Workbox, Ojora Close, Victoria Island, Lagos',
            'registration_number': '0000000',
            'search_number': '0000000',
            'authorized_shared_capital': '10000000',
            'industry': 'Technology Solutions Company',
            'tax_id': 'N/A',
            'registration_date': '2016-01-28T16:06:22.003+00:00',
            'phone': '08000000000',
            'legal_name': 'SMILE IDENTITY NIGERIA LIMITED',
            'state': 'LAGOS',
            'email': 'smile@usesmileid.com',
            'status': 'ACTIVE'
          },
          'fiduciaries': [
            {
              'name': 'Company X',
              'fiduciary_type': 'SECRETARY_COMPANY',
              'address': '10, Workbox, Ojora Close, Victoria Island, Lagos',
              'registration_number': '000000',
              'status': 'N/A'
            }
          ],
          'beneficial_owners': [
            {
              'shareholdings': '100000',
              'address': '10, Workbox, Ojora Close, Victoria Island, Lagos',
              'gender': 'Male',
              'nationality': 'Nigerian',
              'registration_number': 'N/A',
              'name': 'Joe Bloggs',
              'shareholder_type': 'Individual',
              'phone_number': '0123456789'
            },
            {
              'shareholdings': '700000',
              'address': '1234 Main Street Anytown Anystate 00000 USA',
              'gender': 'Not Applicable',
              'nationality': 'N/A',
              'registration_number': '000000',
              'name': 'XYZ Widget Corporation',
              'shareholder_type': 'Corporate',
              'phone_number': '0123456789'
            }
          ],
          'proprietors': [],
          'documents': {
            'search_certificate': ''
          },
          'directors': [
            {
              'shareholdings': '100000',
              'id_number': 'A000000',
              'address': '10, Workbox, Ojora Close, Victoria Island, Lagos',
              'occupation': 'CEO',
              'gender': 'MALE',
              'nationality': 'Nigerian',
              'date_of_birth': '2000-09-20',
              'name': 'Joe Doe Leo',
              'id_type': 'Passport',
              'phone_number': '0123456789'
            },
            {
              'shareholdings': '100000',
              'id_number': 'A000000',
              'address': '1234 Main Street Anytown Anystate 00000 USA',
              'occupation': 'COO',
              'gender': 'FEMALE',
              'nationality': 'American',
              'date_of_birth': '2000-01-01',
              'name': 'Jane Doe',
              'id_type': 'Passport',
              'phone_number': '0123456789'
            }
          ],
          'success': true
        }.to_json

        response = Typhoeus::Response.new(code: 200, body: body)
        Typhoeus.stub('https://testapi.smileidentity.com/v1/business_verification').and_return(response)

        setup_response = connection.send(:setup_requests)
        expect(setup_response).to eq(body)
        # These values come from the `body` mock above:
        expect(JSON.parse(setup_response)['PartnerParams']['user_id']).to eq(payload[:partner_params][:user_id])
        expect(JSON.parse(setup_response)['PartnerParams']['job_id']).to eq(payload[:partner_params][:job_id])
        expect(JSON.parse(setup_response)['PartnerParams']['job_type']).to eq(payload[:partner_params][:job_type])

        # this test does not directly relate to the implementation of the library but it will help us to debug
        # if any keys get removed from the response which will affect the partner.
        expect(JSON.parse(setup_response).keys).to match_array(%w[JSONVersion SmileJobID PartnerParams ResultType
                                                                  ResultText ResultCode IsFinalResult Actions documents
                                                                  company_information proprietors beneficial_owners
                                                                  signature timestamp directors fiduciaries success])
      end
    end

    describe '#build_payload' do
      before do
        connection.instance_variable_set(:@id_info, payload[:id_info])
        connection.instance_variable_set(:@partner_params, payload[:partner_params])
      end

      it 'returns a hash formatted for the request' do
        signature = { 'signature': Base64.strict_encode64('signature'), timestamp: Time.now.to_s }
        allow(connection).to receive(:generate_signature).and_return(signature)
        parsed_response = connection.send(:build_payload)
        expect(parsed_response).to match({ 'timestamp': signature[:timestamp], 'signature': signature[:signature],
                                           'partner_id': partner_id, 'country': 'NG',
                                           'partner_params': payload[:partner_params],
                                           'id_type': payload[:id_info][:id_type],
                                           'id_number': payload[:id_info][:id_number],
                                           'business_type': payload[:id_info][:business_type],
                                           'source_sdk': SmileIdentityCore::SOURCE_SDK,
                                           'source_sdk_version': SmileIdentityCore::VERSION })
      end
    end
  end
end
