RSpec.describe SmileIdentityCore::IDApi do
  let (:partner_id) {'001'}
  let (:api_key) {Base64.encode64( OpenSSL::PKey::RSA.new(1024).public_key.to_pem)}
  let (:sid_server) {0}
  let (:connection) { SmileIdentityCore::IDApi.new(partner_id, api_key, sid_server)}

  let (:partner_params) {
    {
      user_id: 'dmKaJazQCziLc6Tw9lwcgzLo',
      job_id: 'DeXyJOGtaACFFfbZ2kxjuICE',
      job_type: 5
    }
  }

  let (:id_info) {
    {
      first_name: 'John',
      last_name: 'Doe',
      middle_name: '',
      country: 'NG',
      id_type: 'BVN',
      id_number: '00000000000',
      phone_number: '0726789065',
      entered: 'true'
    }
  }

  context 'ensure that the public methods behave correctly' do

    describe '#initialize' do
      it "sets the partner_id, api_key, and sid_server instance variables" do
        expect(connection.instance_variable_get(:@partner_id)).to eq(partner_id)
        expect(connection.instance_variable_get(:@api_key)).to eq(api_key)
        expect(connection.instance_variable_get(:@sid_server)).to eq(sid_server)
      end

      it "sets the correct @url instance variable" do
        expect(connection.instance_variable_get(:@url)).to eq('https://3eydmgh10d.execute-api.us-west-2.amazonaws.com/test')

        connection = SmileIdentityCore::IDApi.new(partner_id, api_key, 'https://something34.api.us-west-2.amazonaws.com/something')
        expect(connection.instance_variable_get(:@url)).to eq('https://something34.api.us-west-2.amazonaws.com/something')
      end
    end

    describe '#submit_job' do
      it "validates the partner_params" do
        no_partner_parameters = nil
        array_partner_params = []
        missing_partner_params = {
          user_id: 'dmKaJazQCziLc6Tw9lwcgzLo',
          job_id: 'DeXyJOGtaACFFfbZ2kxjuICE',
          job_type: nil,
        }

        expect { connection.submit_job(no_partner_parameters, id_info) }
          .to raise_error(ArgumentError, 'Please ensure that you send through partner params')

        expect { connection.submit_job(array_partner_params, id_info) }
          .to raise_error(ArgumentError, 'Partner params needs to be a hash')

        expect { connection.submit_job(missing_partner_params, id_info) }
          .to raise_error(ArgumentError, 'Please make sure that job_type is included in the partner params')
      end

      it 'validates that a job type 5 was submitted' do
        expect {
          connection.submit_job(
            { user_id: 'dmKaJazQCziLc6Tw9lwcgzLo', job_id: 'DeXyJOGtaACFFfbZ2kxjuICE', job_type: 1 },
            id_info)
        }.to raise_error(ArgumentError, 'Please ensure that you are setting your job_type to 5 to query ID Api')
      end

      it 'validates the id_info' do
        expect { connection.submit_job(partner_params, nil) }
          .to raise_error(ArgumentError, "Please make sure that id_info not empty or nil")
        expect { connection.submit_job(partner_params, {}) }
          .to raise_error(ArgumentError, "Please make sure that id_info not empty or nil")

        [:country, :id_type, :id_number].each do |key|
          amended_id_info = id_info.merge(key => '')

          expect { connection.submit_job(partner_params, amended_id_info) }
            .to raise_error(ArgumentError, "Please make sure that #{key.to_s} is included in the id_info")
        end
      end
    end
  end

  context 'ensure that the private methods behave correctly' do
    describe '#symbolize_keys' do
      it 'deeply symbolizes the keys'
    end

    describe '#setup_requests' do
      let(:url) {'https://www.example.com'}

      before(:each) {
        connection.instance_variable_set('@id_info', id_info)
        connection.instance_variable_set('@url', url)
      }

      it 'should return a correct json object if it runs successfully' do
        body = {
          "JSONVersion": "1.0.0",
          "SmileJobID": "0000001096",
          "PartnerParams": {
              "user_id": "dmKaJazQCziLc6Tw9lwcgzLo",
              "job_id": "DeXyJOGtaACFFfbZ2kxjuICE",
              "job_type": 5
          },
          "ResultType": "ID Verification",
          "ResultText": "ID Number Validated",
          "ResultCode": "1012",
          "IsFinalResult": "true",
          "Actions": {
              "Verify_ID_Number": "Verified",
              "Return_Personal_Info": "Returned"
          },
          "Country": "NG",
          "IDType": "BVN",
          "IDNumber": "00000000000",
          "ExpirationDate": "NaN-NaN-NaN",
          "FullName": "some  person",
          "DOB": "NaN-NaN-NaN",
          "Photo": "Not Available",
          "sec_key": "RKYX2ZVpvNTFW8oXdG2rerewererfCdFdRvika0bhJ13ntunAae85e1Fbw9NZli8PE0P0N2cbX5wNCV4Yag4PTCQrLjHG1ZnBHG/Q/Y+sdsdsddsa/rMGyx/m0Jc6w5JrrRDzYsr2ihe5sJEs4Mp1N3iTvQcefV93VMo18LQ/Uco0=|7f0b0d5ebc3e5499c224f2db478e210d1860f01368ebc045c7bbe6969f1c08ba",
          "timestamp": 1570612182124
        }.to_json

        response = Typhoeus::Response.new(code: 200, body: body)
        Typhoeus.stub("#{url}/id_verification").and_return(response)

        setup_response = connection.send(:setup_requests)

        expect(JSON.parse(setup_response)['PartnerParams']['user_id']).to eq(partner_params[:user_id])
        expect(JSON.parse(setup_response)['PartnerParams']['job_id']).to eq(partner_params[:job_id])
        expect(JSON.parse(setup_response)['PartnerParams']['job_type']).to eq(partner_params[:job_type])
        expect(JSON.parse(setup_response)['IDType']).to eq(id_info[:id_type])
        expect(JSON.parse(setup_response)['IDNumber']).to eq(id_info[:id_number])

        # this test does not directly relate to the implementation of the library but it will help us to debug
        # if any keys get removed from the response which will affect the partner.
        expect(JSON.parse(setup_response).keys).to match_array([
          'JSONVersion', 'SmileJobID', 'PartnerParams', 'ResultType', 'ResultText', 'ResultCode',
          'IsFinalResult', 'Actions', 'Country', 'IDType', 'IDNumber', 'ExpirationDate', 'FullName',
          'DOB', 'Photo', 'sec_key', 'timestamp'])
      end
    end

    describe '#configure_json' do
      it "returns a hash formatted for the request" do
        connection.instance_variable_set(:@id_info, { id: 'info', is_merged: 'in, too' })
        connection.instance_variable_set(:@timestamp, 123456789)
        connection.instance_variable_set(:@partner_id, '004')
        connection.instance_variable_set(:@partner_params, 'any partner params')

        parsed_response = JSON.parse(connection.send(:configure_json))
        expect(parsed_response).to match(
          'timestamp' => 123456789,
          'sec_key' => instance_of(String),
          'partner_id' => '004',
          'partner_params' => 'any partner params',
          'id' => 'info',
          'is_merged' => 'in, too'
          )
      end
    end
  end
end
