RSpec.describe SmileIdentityCore do
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
      it "receives the correct attributes and returns an instance" do
        expect(SmileIdentityCore::IDApi).to receive(:new).with(partner_id, api_key, sid_server).and_return(connection)

        connection = SmileIdentityCore::IDApi.new(partner_id, api_key, sid_server)
      end

      [:@partner_id, :@api_key, :@sid_server].each do |instance_variable|
        it "sets the #{instance_variable} instance variable" do
          value = eval(instance_variable.slice(1..instance_variable.length-1))
          expect(connection.instance_variable_get(instance_variable)).to eq(value)
        end
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

        expect { connection.submit_job(no_partner_parameters, id_info) }.to raise_error(ArgumentError, 'Please ensure that you send through partner params')

        expect { connection.submit_job(array_partner_params, id_info) }.to raise_error(ArgumentError, 'Partner params needs to be a hash')

        expect { connection.submit_job(missing_partner_params, id_info) }.to raise_error(ArgumentError, 'Please make sure that job_type is included in the partner params')
      end

      it 'validates that a job type 5 was submitted' do
        expect { connection.submit_job({ user_id: 'dmKaJazQCziLc6Tw9lwcgzLo', job_id: 'DeXyJOGtaACFFfbZ2kxjuICE', job_type: 1 }, id_info) }.to raise_error(ArgumentError, 'Please ensure that you are setting your job_type to 5 to query ID Api')
      end

      it 'validates the id_info' do
        expect{ connection.submit_job(partner_params, nil) }.to raise_error(ArgumentError, "Please make sure that id_info not empty or nil")
        expect{ connection.submit_job(partner_params, {}) }.to raise_error(ArgumentError, "Please make sure that id_info not empty or nil")
      end

      xit 'should return a json object' do
        payload = connection.submit_job(partner_params, id_info)
        # expect(payload).to be_kind_of(Hash)
        # expect(payload).to have_key(key)
      end
    end
  end


  context 'ensure that the private methods behave correctly' do
    describe '#symbolize_keys' do
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
        }

        response = Typhoeus::Response.new(code: 200, body: body)
        Typhoeus.stub("#{url}/id_verification").and_return(response)

        setup_response = connection.send(:setup_requests)

        expect(JSON.parse(setup_response)['PartnerParams']['user_id']).to eq(partner_params[:user_id])
        expect(JSON.parse(setup_response)['PartnerParams']['job_id']).to eq(partner_params[:job_id])
        expect(JSON.parse(setup_response)['PartnerParams']['job_type']).to eq(partner_params[:job_type])
        expect(JSON.parse(setup_response)['IDType']).to eq(id_info[:id_type])
        expect(JSON.parse(setup_response)['IDNumber']).to eq(id_info[:id_number])

        # this test does not directly relate to the implementation of the library but it will help us to debug if any keys get removed from the response which will affect the partner.
        expect(JSON.parse(setup_response).keys).to match_array(['JSONVersion', 'SmileJobID', 'PartnerParams', 'ResultType', 'ResultText', 'ResultCode', 'IsFinalResult', 'Actions', 'Country', 'IDType', 'IDNumber', 'ExpirationDate', 'FullName', 'DOB', 'Photo', 'sec_key', 'timestamp'])

      end
    end

    describe '#configure_json' do
      let(:parsed_response) { JSON.parse(connection.send(:configure_json)) }

      before(:each) {
        connection.instance_variable_set('@id_info', id_info)
      }

      it 'returns the correct data type' do
        expect(parsed_response).to be_kind_of(Hash)
      end

      ['timestamp', 'sec_key', 'partner_id', 'partner_params', 'id_number', 'id_type'].each do |key|
        it "includes the #{key} key" do
          expect(parsed_response).to have_key(key)
        end
      end
    end

    describe '#determine_sec_key' do
      # NOTE: more testing done in Signature class
      it 'contains a join in the signature' do
        expect(connection.send(:determine_sec_key)).to include('|')
      end
    end


  end

end
