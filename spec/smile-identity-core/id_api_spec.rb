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
          user_id: '1',
          job_id: '2',
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
    end

    describe '#configure_json' do
    end
  end

end
