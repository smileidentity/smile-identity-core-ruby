# frozen_string_literal: true

RSpec.describe SmileIdentityCore::IDApi do
  let(:partner_id) { ENV.fetch('SMILE_PARTNER_ID') }
  let(:api_key) { ENV.fetch('SMILE_API_KEY') }
  let(:sid_server) { ENV.fetch('SMILE_SERVER_ENVIRONMENT', 0) }
  let(:connection) { SmileIdentityCore::IDApi.new(partner_id, api_key, sid_server) }

  let(:partner_params) do
    {
      user_id: SecureRandom.uuid,
      job_id: SecureRandom.uuid,
      job_type: SmileIdentityCore::JOB_TYPE::ENHANCED_KYC
    }
  end

  let(:id_info) do
    {
      first_name: 'John',
      last_name: 'Doe',
      middle_name: '',
      country: 'GH',
      id_type: 'DRIVERS_LICENSE',
      id_number: '00000000000',
      phone_number: '0726789065',
      entered: 'true'
    }
  end

  context 'ensure that the public methods behave correctly' do
    describe '#initialize' do
      it 'sets the partner_id, api_key, and sid_server instance variables' do
        expect(connection.instance_variable_get(:@partner_id)).to eq(partner_id)
        expect(connection.instance_variable_get(:@api_key)).to eq(api_key)
      end

      it 'sets the correct @url instance variable' do
        expect(connection.instance_variable_get(:@url)).to eq('https://testapi.smileidentity.com/v1')

        connection = described_class.new(partner_id, api_key, 'https://something34.api.us-west-2.amazonaws.com/something')
        expect(connection.instance_variable_get(:@url)).to eq('https://something34.api.us-west-2.amazonaws.com/something')
      end
    end

    describe '#submit_job' do
      it 'validates the partner_params' do
        no_partner_parameters = nil
        array_partner_params = []
        missing_partner_params = {
          user_id: 'dmKaJazQCziLc6Tw9lwcgzLo',
          job_id: 'DeXyJOGtaACFFfbZ2kxjuICE',
          job_type: nil
        }

        expect { connection.submit_job(no_partner_parameters, id_info) }
          .to raise_error(ArgumentError, 'Please ensure that you send through partner params')

        expect { connection.submit_job(array_partner_params, id_info) }
          .to raise_error(ArgumentError, 'Partner params needs to be a hash')

        expect { connection.submit_job(missing_partner_params, id_info) }
          .to raise_error(ArgumentError, 'Please make sure that job_type is included in the partner params')
      end

      it 'validates that a job type 5 was submitted' do
        expect do
          connection.submit_job(
            { user_id: 'dmKaJazQCziLc6Tw9lwcgzLo', job_id: 'DeXyJOGtaACFFfbZ2kxjuICE', job_type: 1 },
            id_info
          )
        end.to raise_error(ArgumentError, 'Please ensure that you are setting your job_type to 5 to query ID Api')
      end

      it 'validates the id_info' do
        expect { connection.submit_job(partner_params, nil) }
          .to raise_error(ArgumentError, 'Please make sure that id_info not empty or nil')
        expect { connection.submit_job(partner_params, {}) }
          .to raise_error(ArgumentError, 'Please make sure that id_info not empty or nil')

        %i[country id_type id_number].each do |key|
          amended_id_info = id_info.merge(key => '')

          expect { connection.submit_job(partner_params, amended_id_info) }
            .to raise_error(ArgumentError, "Please make sure that #{key} is included in the id_info")
        end
      end
    end
  end

  context 'ensure that the private methods behave correctly' do
    describe '#submit_job' do
      it 'returns a correct json object if it runs successfully' do
        parsed_response = {}
        # Make real request for the first time, we then use a saved version for extra requests
        VCR.use_cassette('id_verification', :record => :new_episodes, :match_requests_on => [:body]) do
          setup_response = connection.submit_job(partner_params, id_info, { signature: true })
          parsed_response = JSON.parse(setup_response)
        end

        # Assert the payload against the fields that will always be present
        expect(parsed_response['PartnerParams']['user_id']).to eq(partner_params[:user_id])
        # check for presence since the generated will be different from the saved response in the cassette
        expect(parsed_response['PartnerParams']['job_id']).not_to be(nil)
        expect(parsed_response['PartnerParams']['job_type']).to eq(partner_params[:job_type])
        expect(parsed_response['IDType']).to eq(id_info[:id_type])
        expect(parsed_response['IDNumber']).to eq(id_info[:id_number])

        # this test does not directly relate to the implementation of the library but it will help us to debug
        # if any keys get removed from the response which will affect the partner.
        expect(parsed_response.keys).to match_array(%w[JSONVersion SmileJobID PartnerParams ResultType ResultText
                                                       ResultCode IsFinalResult Actions Country IDType IDNumber timestamp Source signature])
      end
    end

    describe '#configure_json' do
      before do
        connection.instance_variable_set(:@id_info, { id: 'info', is_merged: 'in, too' })
        connection.instance_variable_set(:@partner_id, '004')
        connection.instance_variable_set(:@partner_params, 'any partner params')
      end

      it 'returns a hash formatted for the request' do
        parsed_response = JSON.parse(connection.send(:configure_json))
        expect(parsed_response).to match(
          'timestamp' => /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [-+]\d{4}/, # new signature!,
          'signature' => instance_of(String),
          'partner_id' => '004',
          'partner_params' => 'any partner params',
          'id' => 'info',
          'is_merged' => 'in, too',
          'source_sdk' => SmileIdentityCore::SOURCE_SDK,
          'source_sdk_version' => SmileIdentityCore::VERSION
        )
        expect(parsed_response).not_to have_key 'sec_key'
      end
    end
  end
end
