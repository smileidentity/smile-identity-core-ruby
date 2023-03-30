# frozen_string_literal: true

RSpec.describe SmileIdentityCore::Aml do
  let(:partner_id) { '001' }
  let(:api_key) { Base64.encode64(OpenSSL::PKey::RSA.new(1024).public_key.to_pem) }
  let(:sid_server) { 0 }
  let(:connection) { described_class.new(partner_id, api_key, sid_server) }

  let(:payload) do
    {
      partner_params: {
        user_id: 'aml_test_user_008',
        job_id: 'DeXyJOGtaACFFfbZ2kxjuICE',
        job_type: SmileIdentityCore::JobType::AML
      },
      id_info: {
        countries: ['US'],
        full_name: 'John Leo Doe',
        birth_year: '1984'
      },
      options: {
        search_existing_user: false
      }
    }
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

    it 'throws ArgumentError when the job type is not 10' do
      expect do
        connection.submit_job(payload[:partner_params].merge(job_type: 1), payload[:id_info])
      end.to raise_error(ArgumentError,
                         'Please ensure that you are setting your job_type to 10 to query AML')
    end

    it 'throws ArgumentError if id_info is nil' do
      expect { connection.submit_job(payload[:partner_params], nil) }
        .to raise_error(ArgumentError, 'Please make sure that id_info is not empty or nil')
    end

    it 'throws ArgumentError if id_info is empty' do
      expect { connection.submit_job(payload[:partner_params], {}) }
        .to raise_error(ArgumentError, 'Please make sure that id_info is not empty or nil')
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
          "Actions": {
            "Listed": 'Listed'
          },
          "PartnerParams": {
            "job_type": 10,
            "user_id": 'aml_test_user_008',
            "job_id": 'DeXyJOGtaACFFfbZ2kxjuICE'
          },
          "SmileJobID": '0000000411',
          "no_of_persons_found": 1,
          "people": [
            {
              "addresses": [
                'Burbank'
              ],
              "adverse_media": [
                {
                  "date_published": '2021-09-24',
                  "publisher": 'Regulatory Times',
                  "source_link": 'https:regulatorytimes.com/article',
                  "title": 'Jon Doe angered regulators'
                }
              ],
              "aliases": [
                'John Doe'
              ],
              "associations": [
                {
                  "association_type": 'PEP',
                  "name": 'Bob Smith',
                  "relationship": 'Bob Smith is an associate of John Leo Doe'
                }
              ],
              "dates_of_birth": [
                '1984-07-16'
              ],
              "name": 'John Leo Doe',
              "nationalities": [
                'American'
              ],
              "pep": {
                "pep_level": 1,
                "political_positions": [
                  {
                    "country": 'United States',
                    "from": '2020-01-05',
                    "position": 'Representative',
                    "to": '2022-01-05'
                  },
                  {
                    "country": 'United States',
                    "from": '2022-01-05',
                    "position": 'Senator',
                    "to": nil
                  }
                ],
                "sources": [
                  {
                    "source_link": 'https://www.senate.gov/senators/',
                    "source_name": 'senate.gov'
                  }
                ]
              },
              "sanctions": [
                {
                  "date_of_birth": '',
                  "nationality": 'American',
                  "source_details": {
                    "listed_date": '2020-01-05',
                    "source_link": [
                      'https://sanctionslist.com'
                    ],
                    "source_name": 'Office of Foreign Assets Control (OFAC)',
                    "source_type": 'Sanctions'
                  }
                }
              ]
            }
          ],
          "ResultCode": '1030',
          "ResultText": 'Found on list',
          "signature": '...',
          "timestamp": '2023-02-17T16:24:16.835Z'
        }.to_json

        response = Typhoeus::Response.new(code: 200, body: body)
        Typhoeus.stub('https://testapi.smileidentity.com/v1/aml').and_return(response)

        setup_response = connection.send(:setup_requests)
        expect(setup_response).to eq(body)
        # These values come from the `body` mock above:
        expect(JSON.parse(setup_response)['PartnerParams']['user_id']).to eq(payload[:partner_params][:user_id])
        expect(JSON.parse(setup_response)['PartnerParams']['job_id']).to eq(payload[:partner_params][:job_id])
        expect(JSON.parse(setup_response)['PartnerParams']['job_type']).to eq(payload[:partner_params][:job_type])

        # this test does not directly relate to the implementation of the library but it will help us to debug
        # if any keys get removed from the response which will affect the partner.
        expect(JSON.parse(setup_response).keys).to match_array(%w[SmileJobID PartnerParams people
                                                                  ResultText ResultCode Actions
                                                                  signature timestamp no_of_persons_found
                                                                  ])
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
                                           'partner_id': partner_id,
                                           'partner_params': payload[:partner_params],
                                           'user_id': payload[:partner_params][:user_id],
                                           'job_id': payload[:partner_params][:job_id],
                                           'full_name': payload[:id_info][:full_name],
                                           'full_name': payload[:id_info][:full_name],
                                           'countries': payload[:id_info][:countries],
                                           'birth_year': payload[:id_info][:birth_year],
                                           'source_sdk': SmileIdentityCore::SOURCE_SDK,
                                           'source_sdk_version': SmileIdentityCore::VERSION })
      end
    end
  end
end
