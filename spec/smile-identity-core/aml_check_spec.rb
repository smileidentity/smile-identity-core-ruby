# frozen_string_literal: true

RSpec.describe SmileIdentityCore::AmlCheck do
  let(:partner_id) { '001' }
  let(:api_key) { Base64.encode64(OpenSSL::PKey::RSA.new(1024).public_key.to_pem) }
  let(:sid_server) { 0 }
  let(:connection) { described_class.new(partner_id, api_key, sid_server) }

  let(:payload) do
    {
      user_id: 'aml_test_user_008',
      job_id: 'DeXyJOGtaACFFfbZ2kxjuICE',
      job_type: SmileIdentityCore::JobType::AML,
      countries: ['US'],
      full_name: 'John Leo Doe',
      birth_year: '1984',
      search_existing_user: false,
    }
  end

  let(:aml_response) do
    {
      Actions: {
        Listed: 'Listed',
      },
      PartnerParams: {
        job_type: 10,
        user_id: 'aml_test_user_008',
        job_id: 'DeXyJOGtaACFFfbZ2kxjuICE',
      },
      SmileJobID: '0000000411',
      no_of_persons_found: 1,
      people: [
        {
          addresses: [
            'Burbank',
          ],
          adverse_media: [
            {
              date_published: '2021-09-24',
              publisher: 'Regulatory Times',
              source_link: 'https:regulatorytimes.com/article',
              title: 'Jon Doe angered regulators',
            },
          ],
          aliases: [
            'John Doe',
          ],
          associations: [
            {
              association_type: 'PEP',
              name: 'Bob Smith',
              relationship: 'Bob Smith is an associate of John Leo Doe',
            },
          ],
          dates_of_birth: [
            '1984-07-16',
          ],
          name: 'John Leo Doe',
          nationalities: [
            'American',
          ],
          pep: {
            pep_level: 1,
            political_positions: [
              {
                country: 'United States',
                from: '2020-01-05',
                position: 'Representative',
                to: '2022-01-05',
              },
              {
                country: 'United States',
                from: '2022-01-05',
                position: 'Senator',
                to: nil,
              },
            ],
            sources: [
              {
                source_link: 'https://www.senate.gov/senators/',
                source_name: 'senate.gov',
              },
            ],
          },
          sanctions: [
            {
              date_of_birth: '',
              nationality: 'American',
              source_details: {
                listed_date: '2020-01-05',
                source_link: [
                  'https://sanctionslist.com',
                ],
                source_name: 'Office of Foreign Assets Control (OFAC)',
                source_type: 'Sanctions',
              },
            },
          ],
        },
      ],
      ResultCode: '1030',
      ResultText: 'Found on list',
      signature: '...',
      timestamp: '2023-02-17T16:24:16.835Z',
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
      connection.instance_variable_set('@payload', {})
      connection.instance_variable_set('@params', payload)
    end

    it 'sets source_sdk in the payload' do
      connection.send(:add_sdk_info)
      expect(connection.instance_variable_get('@payload')[:source_sdk]).to eq(SmileIdentityCore::SOURCE_SDK)
    end

    it 'sets source_sdk_version in the payload' do
      connection.send(:add_sdk_info)
      expect(connection.instance_variable_get('@payload')[:source_sdk_version]).to eq(SmileIdentityCore::VERSION)
    end

    describe 'returns a correct json object if' do
      before do
        response = Typhoeus::Response.new(code: 200, body: aml_response)
        Typhoeus.stub('https://testapi.smileidentity.com/v1/aml').and_return(response)
      end

      it '#submit_requests it runs successfully' do
        setup_response = connection.send(:submit_requests)

        expect(setup_response).to eq(aml_response)
        # These values come from the `body` mock above:
        expect(JSON.parse(setup_response)['PartnerParams']['user_id']).to eq(payload[:user_id])
        expect(JSON.parse(setup_response)['PartnerParams']['job_id']).to eq(payload[:job_id])
        expect(JSON.parse(setup_response)['PartnerParams']['job_type']).to eq(payload[:job_type])

        # this test does not directly relate to the implementation of the library but it will help us to debug
        # if any keys get removed from the response which will affect the partner.
        expect(JSON.parse(setup_response).keys).to match_array(%w[
          SmileJobID PartnerParams people
          ResultText ResultCode Actions
          signature timestamp no_of_persons_found
        ])
      end

      it '#submit_job it runs successfully' do
        setup_response = connection.submit_job(payload)
        # These values come from the `body` mock above:
        expect(JSON.parse(setup_response)['PartnerParams']['user_id']).to eq(payload[:user_id])
        expect(JSON.parse(setup_response)['PartnerParams']['job_id']).to eq(payload[:job_id])
        expect(JSON.parse(setup_response)['PartnerParams']['job_type']).to eq(payload[:job_type])

        # this test does not directly relate to the implementation of the library but it will help us to debug
        # if any keys get removed from the response which will affect the partner.
        expect(JSON.parse(setup_response).keys).to match_array(%w[
          SmileJobID PartnerParams people
          ResultText ResultCode Actions
          signature timestamp no_of_persons_found
        ])
      end
    end

    describe '#build_payload' do
      before do
        connection.instance_variable_set(:@params, payload)
      end

      it 'returns a hash formatted for the request' do
        signature = { signature: Base64.strict_encode64('signature'), timestamp: Time.zone.now.to_s }
        allow(connection).to receive(:generate_signature).and_return(signature)
        parsed_response = connection.send(:build_payload)
        expect(parsed_response).to match({
          timestamp: signature[:timestamp],
          signature: signature[:signature],
          partner_id: partner_id,
          user_id: payload[:user_id],
          job_id: payload[:job_id],
          full_name: payload[:full_name],
          job_type: SmileIdentityCore::JobType::AML,
          countries: payload[:countries],
          search_existing_user: payload[:search_existing_user],
          birth_year: payload[:birth_year],
          source_sdk: SmileIdentityCore::SOURCE_SDK,
          source_sdk_version: SmileIdentityCore::VERSION,
        })
      end

      it 'returns a hash formatted for the request with optional params' do
        connection.instance_variable_set(:@optional_info, { user_email: 'johndoe@email.com' })

        signature = { signature: Base64.strict_encode64('signature'), timestamp: Time.zone.now.to_s }
        allow(connection).to receive(:generate_signature).and_return(signature)
        parsed_response = connection.send(:build_payload)
        expect(parsed_response).to match({
          timestamp: signature[:timestamp],
          signature: signature[:signature],
          partner_id: partner_id,
          partner_params: { user_email: 'johndoe@email.com' },
          user_id: payload[:user_id],
          job_id: payload[:job_id],
          job_type: SmileIdentityCore::JobType::AML,
          search_existing_user: payload[:search_existing_user],
          full_name: payload[:full_name],
          countries: payload[:countries],
          birth_year: payload[:birth_year],
          source_sdk: SmileIdentityCore::SOURCE_SDK,
          source_sdk_version: SmileIdentityCore::VERSION,
        })
      end
    end

    it 'successfully submits a job' do
      connection.instance_variable_set(:@params, nil)
      connection.instance_variable_set(:@optional_info, nil)

      signature = { signature: Base64.strict_encode64('signature'), timestamp: Time.zone.now.to_s }
      allow(connection).to receive(:generate_signature).and_return(signature)
    end
  end
end
