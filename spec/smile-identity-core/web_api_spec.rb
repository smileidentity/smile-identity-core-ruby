# frozen_string_literal: true

RSpec.describe SmileIdentityCore::WebApi do
  let(:partner_id) { ENV.fetch('SMILE_PARTNER_ID') }
  let(:default_callback) { 'www.default_callback.com' }
  let(:api_key) { ENV.fetch('SMILE_API_KEY') }
  let(:sid_server) { ENV.fetch('SMILE_SERVER_ENVIRONMENT', SmileIdentityCore::ENV::TEST) }
  let(:connection) { described_class.new(partner_id, default_callback, api_key, sid_server) }

  let(:partner_params) do
    {
      user_id: SecureRandom.uuid,
      job_id: SecureRandom.uuid,
      job_type: SmileIdentityCore::JOB_TYPE::BIOMETRIC_KYC
    }
  end

  let(:images) do
    [
      {
        image_type_id: SmileIdentityCore::IMAGE_TYPE::SELFIE_IMAGE_FILE,
        image: File.new('./spec/fixtures/selfie.jpg')
      },
      {
        image_type_id: SmileIdentityCore::IMAGE_TYPE::ID_CARD_IMAGE_FILE,
        image: File.new('./spec/fixtures/id_image.jpg')
      }
    ]
  end

  let(:images_v2) do
    [
      {
        image_type_id: SmileIdentityCore::IMAGE_TYPE::SELFIE_IMAGE_FILE,
        image: File.new('./spec/fixtures/selfie.jpg')
      },
      {
        image_type_id: SmileIdentityCore::IMAGE_TYPE::ID_CARD_BACK_IMAGE_BASE64,
        image: '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'
      }

    ]
  end

  let(:id_info) do
    {
      first_name: 'John',
      last_name: 'Doe',
      middle_name: '',
      country: 'GH',
      id_type: 'DRIVERS_LICENSE',
      id_number: '00000000000',
      entered: 'true'
    }
  end

  let(:options) do
    {
      optional_callback: 'www.optional_callback.com',
      return_job_status: false,
      return_image_links: false,
      return_history: false
    }
  end

  it 'has a version number' do
    expect(SmileIdentityCore::VERSION).not_to be nil
  end

  context 'ensure that the public methods behave correctly' do
    describe '#initialize' do
      it 'sets the partner_id, api_key, and sid_server instance variables' do
        expect(connection.instance_variable_get(:@partner_id)).to eq(partner_id)
        expect(connection.instance_variable_get(:@api_key)).to eq(api_key)
        expect(connection.instance_variable_get(:@sid_server)).to eq(sid_server)
      end

      it 'sets the @callback_url instance variable' do
        value = default_callback
        expect(connection.instance_variable_get(:@callback_url)).to eq(value)
      end

      it 'sets the correct @url instance variable' do
        expect(connection.instance_variable_get(:@url)).to eq('https://testapi.smileidentity.com/v1')

        connection = described_class.new(
          partner_id, default_callback, api_key, 'https://something34.api.us-west-2.amazonaws.com/something'
        )
        expect(connection.instance_variable_get(:@url)).to eq('https://something34.api.us-west-2.amazonaws.com/something')
      end
    end

    describe '#submit_job' do
      context 'with validation' do
        it 'validates the partner_params' do
          no_partner_parameters = nil
          array_partner_params = []
          missing_partner_params = {
            user_id: '1',
            job_id: '2',
            job_type: nil
          }

          expect { connection.submit_job(no_partner_parameters, images, id_info, options) }
            .to raise_error(ArgumentError, 'Please ensure that you send through partner params')

          expect { connection.submit_job(array_partner_params, images, id_info, options) }
            .to raise_error(ArgumentError, 'Partner params needs to be a hash')

          expect { connection.submit_job(missing_partner_params, images, id_info, options) }
            .to raise_error(ArgumentError, 'Please make sure that job_type is included in the partner params')
        end

        it 'validates the images' do
          no_images = nil
          hash_images = {}
          empty_images = []
          just_id_image = [
            {
              image_type_id: SmileIdentityCore::IMAGE_TYPE::ID_CARD_BACK_IMAGE_FILE,
              image_path: './tmp/id_image.jpg'
            }
          ]

          expect { connection.submit_job(partner_params, no_images, id_info, options) }
            .to raise_error(ArgumentError, 'Please ensure that you send through image details')

          expect { connection.submit_job(partner_params, hash_images, id_info, options) }
            .to raise_error(ArgumentError, 'Image details needs to be an array')

          expect { connection.submit_job(partner_params, empty_images, id_info, options) }
            .to raise_error(ArgumentError, 'You need to send through at least one selfie image')

          expect { connection.submit_job(partner_params, just_id_image, id_info, options) }
            .to raise_error(ArgumentError, 'You need to send through at least one selfie image')
        end

        it 'validates the id_info' do
          %i[country id_type id_number].each do |key|
            amended_id_info = id_info.merge(key => '')

            expect { connection.submit_job(partner_params, images, amended_id_info, options) }
              .to raise_error(ArgumentError, "Please make sure that #{key} is included in the id_info")
          end
        end

        describe 'validating the options' do
          let(:good_options) do
            {
              optional_callback: 'wwww.optional_callback.com',
              return_job_status: false,
              return_image_links: false,
              return_history: false
            }
          end

          it 'checks that return_job_status is a boolean' do
            bad_options = good_options.merge(return_job_status: 'false')
            expect { connection.submit_job(partner_params, images, id_info, bad_options) }
              .to raise_error(ArgumentError, 'return_job_status needs to be a boolean')
          end
        end
      end

      it 'updates the callback_url when optional_callback is defined' do
        # This is really about setting config...from options to an ivar. It's confused because all the other
        # config is good, so we fire off two HTTP requests, and we need to mock them.

        # Set everything up:

        # allow(IO).to receive(:read).with('./spec/fixtures/selfie.jpg').and_return('')
        # allow(IO).to receive(:read).with('./tmp/id_image.jpg').and_return('')

        # Test the preconditions! `default_callback` is what `connection` was instantiated with.
        expect(connection.instance_variable_get(:@callback_url)).to eq(default_callback)

        # Run the code, passing the `optional_callback` option:
        VCR.use_cassette('webapi_verification', preserve_exact_body_bytes: true) do
          connection.submit_job(partner_params, images, id_info, options.merge(optional_callback: 'https://zombo.com'))
        end

        # Make sure @callback_url gets set:
        expect(connection.instance_variable_get(:@callback_url)).to eq('https://zombo.com')
      end

      # xit 'ensures that we only except a png or jpg' do
      #   # check the image_path
      # end
    end
  end

  context 'ensure that the private methods behave correctly' do
    # NOTE: In this gem, we do test the private methods because we have split up a lot of
    # the logic into private methods that feed into the public method.

    describe '#validate_return_data' do
      it 'validates that data is returned via the callback or job_status' do
        connection.instance_variable_set('@callback_url', '')
        connection.instance_variable_set('@options', options.merge(return_job_status: true))
        expect { connection.send(:validate_return_data) }.not_to raise_error

        connection.instance_variable_set('@options', options)
        expect { connection.send(:validate_return_data) }
          .to raise_error(ArgumentError,
                          'Please choose to either get your response via the callback or job status query')

        connection.instance_variable_set('@options', options.merge(return_job_status: true))
        connection.instance_variable_set('@callback_url', default_callback)
        expect { connection.send(:validate_return_data) }.not_to raise_error
      end
    end

    describe '#validate_enroll_with_id' do
      before do
        connection.instance_variable_set('@images', [
                                           {
                                             image_type_id: SmileIdentityCore::IMAGE_TYPE::SELFIE_IMAGE_FILE,
                                             image: './tmp/selfie1.png'
                                           },
                                           {
                                             image_type_id: SmileIdentityCore::IMAGE_TYPE::SELFIE_IMAGE_FILE,
                                             image: './tmp/selfie2.png'
                                           }
                                         ])
        connection.instance_variable_set('@id_info',
                                         {
                                           first_name: '',
                                           last_name: '',
                                           middle_name: '',
                                           country: '',
                                           id_type: '',
                                           id_number: '',
                                           entered: 'false'
                                         })
      end

      it 'validates the id parameters required for job_type 1' do
        expect { connection.send(:validate_enroll_with_id) }
          .to raise_error(ArgumentError,
                          'You are attempting to complete a job type 1 without providing an id card image or id info')

        connection.instance_variable_set('@images', images)
        expect { connection.send(:validate_enroll_with_id) }.not_to raise_error
      end
    end

    describe '#check_boolean' do
      it 'returns false for the key if the object does not exist' do
        options = {}
        expect(connection.send(:check_boolean, :return_job_status, options)).to be(false)
      end

      it 'returns false if a key is nil or does not exist' do
        expect(connection.send(:check_boolean, :return_job_status, nil)).to be(false)
      end

      it 'returns the boolean value as it is when it as a boolean' do
        expect(connection.send(:check_boolean, :return_job_status, { return_job_status: true })).to be(true)
        expect(connection.send(:check_boolean, :image_links, { image_links: false })).to be(false)
      end
    end

    describe '#check_string' do
      it "returns '' for the key if the object does not exist" do
        options = {}
        expect(connection.send(:check_string, :optional_callback, options)).to eq('')
      end

      it "returns '' if a key is nil or does not exist" do
        expect(connection.send(:check_string, :optional_callback, nil)).to eq('')
      end

      it 'returns the string as it is when it exists' do
        expect(connection.send(:check_string, :optional_callback, { optional_callback: 'www.optional_callback' }))
          .to eq('www.optional_callback')
      end
    end

    describe '#configure_prep_upload_json' do
      let(:parsed_response) { JSON.parse(connection.send(:configure_prep_upload_json)) }

      it 'returns the correct data type' do
        connection.instance_variable_set(:@partner_id, '001')
        connection.instance_variable_set(:@partner_params, 'some partner params')
        connection.instance_variable_set(:@callback_url, 'www.example.com')

        expect(parsed_response).to match(
          'signature' => instance_of(String),
          'timestamp' => /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [-+]\d{4}/, # new signature!,
          'file_name' => 'selfie.zip', # The code hard-codes this value
          'smile_client_id' => '001',
          'partner_params' => 'some partner params',
          'model_parameters' => {}, # The code hard-codes this value
          'callback_url' => 'www.example.com',
          'source_sdk' => SmileIdentityCore::SOURCE_SDK,
          'source_sdk_version' => SmileIdentityCore::VERSION
        )
        expect(parsed_response).to have_key 'signature'
      end
    end

    describe 'setup_requests' do
      # all the methods called in setup requests are already being tested individually

      it 'returns a json object if it runs successfully' do
        # allow(IO).to receive(:read).with('./spec/fixtures/selfie.jpg').and_return('')
        # allow(IO).to receive(:read).with('./tmp/id_image.jpg').and_return('')

        connection.instance_variable_set('@images', images)
        connection.instance_variable_set('@options', options)

        parsed_response = {}
        VCR.use_cassette('webapi_verification', preserve_exact_body_bytes: true) do
          setup_response = connection.send(:setup_requests)
          parsed_response = JSON.parse(setup_response)
        end

        expect(parsed_response['success']).to be_truthy
      end

      it 'returns the correct message if we could not get an http response' do
        VCR.use_cassette('webapi_verification_error') do
          expect { connection.send(:setup_requests) }.to raise_error(RuntimeError)
        end
      end

      it 'returns the correct message if we received a non-successful http response' do
        # response = Typhoeus::Response.new(code: 403, body: 'Some error')

        VCR.use_cassette('webapi_verification_error') do
          expect { connection.send(:setup_requests) }.to raise_error(RuntimeError)
        end
      end

      it 'returns the correct message if there is a timeout' do
        # find the correct code
        # response = Typhoeus::Response.new(code: 512, body: 'Some error')
        VCR.use_cassette('webapi_verification_error') do
          expect { connection.send(:setup_requests) }.to raise_error(RuntimeError)
        end
      end
    end

    describe '#configure_info_json' do
      # NOTE: we can perhaps still test that the instance variables that are set in teh payload are the ones set in the connection
      before do
        connection.instance_variable_set('@id_info', 'a value for @id_info')
        connection.instance_variable_set('@images', images)
      end

      let(:configure_info_json) { connection.send(:configure_info_json, 'the server information url') }

      it 'includes the relevant keys on the root level' do
        expect(configure_info_json.fetch(:images)).to be_kind_of(Array)
        expect(configure_info_json.fetch(:id_info)).to eq('a value for @id_info')
        expect(configure_info_json.fetch(:server_information)).to eq('the server information url')
      end

      describe 'the package_information inner payload' do
        it 'includes its relevant keys' do
          [:apiVersion].each do |key|
            expect(connection.send(:configure_info_json,
                                   'the server information url')[:package_information]).to have_key(key)
          end
        end

        it 'includes the relevant keys for the nested apiVersion' do
          %i[buildNumber majorVersion minorVersion].each do |key|
            expect(connection.send(:configure_info_json,
                                   'the server information url')[:package_information][:apiVersion]).to have_key(key)
          end
        end

        it 'sets the correct version information' do
          expect(connection.send(:configure_info_json,
                                 'the server information url')[:package_information][:apiVersion][:buildNumber]).to be(0)
          expect(connection.send(:configure_info_json,
                                 'the server information url')[:package_information][:apiVersion][:majorVersion]).to be(2)
          expect(connection.send(:configure_info_json,
                                 'the server information url')[:package_information][:apiVersion][:minorVersion]).to be(0)
        end
      end

      describe 'the misc_information inner payload' do
        it 'includes its relevant keys' do
          connection.instance_variable_set(:@partner_id, 'partner id')
          connection.instance_variable_set(:@partner_params, 'partner params')
          connection.instance_variable_set(:@callback_url, 'example.com')

          expect(configure_info_json.fetch(:misc_information)).to match(
            partner_params: 'partner params',
            smile_client_id: 'partner id',
            callback_url: 'example.com',
            timestamp: /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [-+]\d{4}/, # new signature!,
            signature: instance_of(String), # new signature!
            userData: instance_of(Hash), # hard-coded, and spec'd below
            retry: 'false', # hard-coded
            file_name: 'selfie.zip' # hard-coded
          )
          expect(configure_info_json.fetch(:misc_information)).to have_key(:signature)
        end

        it 'includes the relevant keys for the nested userData' do
          %i[isVerifiedProcess name fbUserID firstName lastName gender email phone countryCode
             countryName].each do |key|
            expect(configure_info_json.fetch(:misc_information).fetch(:userData)).to have_key(key)
          end
        end
      end
    end

    describe '#configure_image_payload' do
      before do
        connection.instance_variable_set('@images', images_v2)
      end

      it 'returns the correct data type' do
        expect(connection.send(:configure_image_payload)).to be_kind_of(Array)
      end

      it 'includes the relevant keys in the hash of the array' do
        %i[image_type_id image file_name].each do |key|
          expect(connection.send(:configure_image_payload)[0]).to have_key(key)
        end
      end

      it 'correctly sets the image type value' do
        expect(connection.send(:configure_image_payload)[0][:image_type_id]).to eq(images_v2[0][:image_type_id])
        expect(connection.send(:configure_image_payload)[1][:image_type_id]).to eq(images_v2[1][:image_type_id])
      end

      it 'correctly sets the image value' do
        expect(connection.send(:configure_image_payload)[0][:image]).to eq('')
        expect(connection.send(:configure_image_payload)[1][:image]).to eq(images_v2[1][:image])
      end

      it 'correctly sets the file_name value' do
        expect(connection.send(:configure_image_payload)[0][:file_name]).to eq(File.basename(images_v2[0][:image]))
        expect(connection.send(:configure_image_payload)[1][:file_name]).to eq('')
      end
    end

    describe '#zip_up_file' do
      before do
        # allow(IO).to receive(:read).with('./spec/fixtures/selfie.jpg').and_return('')
        # allow(IO).to receive(:read).with('./tmp/id_image.jpg').and_return('')
        connection.instance_variable_set('@images', images)
      end

      let(:info_json) do
        {
          package_information: {
            apiVersion: {
              buildNumber: 0,
              majorVersion: 2,
              minorVersion: 1
            }
          },
          misc_information: {
            sec_key: "zWzSzfvXzvN0MdPHtW78a9w3Zlyy7k9UY6Li7pikHniTeuma2/9gzZsZIMVy\n/NhMyK0crjvLeheZdZ2mEFqDAOYmP4JVZHkHZDC1ZDm4UnfUiO5lJa+Jmow5\nELLpSyJzHVaD8thGVHh2qcSfNIaMYMpAJOjjrQv9/aFEpZq+Ar0=\n|ba813d3fafa33a0edd77d968d6ba89e406a7ck1eemn5b042be0fab053723rtyu",
            retry: 'false',
            partner_params: partner_params,
            timestamp: 1_562_938_446,
            file_name: 'selfie.zip',
            smile_client_id: partner_id,
            callback_url: '',
            userData: {
              isVerifiedProcess: false,
              name: '',
              fbUserID: '',
              firstName: 'Bill',
              lastName: '',
              gender: '',
              email: '',
              phone: '',
              countryCode: '+',
              countryName: ''
            }
          },
          id_info: id_info,
          images: connection.send(:configure_image_payload),
          server_information: {
            'upload_url' => 'https://some_url.com/videos/125/125-0000000549-vzegm7mb23rznn5e1lepyij444olpa/selfie.zip',
            'ref_id' => '125-0000000549-vzegm7mb23rznn5e1lepyij444olpa',
            'smile_job_id' => '0000000549',
            'camera_config' => 'null',
            'code' => '2202'
          }
        }
      end

      let(:zip_up_file) { connection.send(:zip_up_file, info_json) }

      it 'returns the correct object type after being zipped' do
        expect(zip_up_file).to be_a_kind_of(StringIO)
      end

      it 'returns an object with a size greater than 0' do
        zip_up_file.rewind
        size = zip_up_file.size
        expect(size).to be > 0
      end

      context 'with only physical files' do
        it 'contains the necessary files in the zip' do
          zip_up_file.rewind
          file = zip_up_file.read
          expect(file).to include('info.json')
          expect(file).to include('selfie.jpg')
          expect(file).to include('id_image.jpg')
        end
      end

      context 'with a combination of physical and base 64 files' do
        before do
          # allow(IO).to receive(:read).with('./spec/fixtures/selfie.jpg').and_return('')
          # allow(IO).to receive(:read).with('./tmp/id_image.jpg').and_return('')
          connection.instance_variable_set('@images', images_v2)
        end

        let(:info_json_v2) do
          {
            package_information: {
              apiVersion: {
                buildNumber: 0,
                majorVersion: 2,
                minorVersion: 1
              }
            },
            misc_information: {
              sec_key: "zWzSzfvXzvN0MdPHtW7879w3Zlyy7k9UY6Li7pikHniTUuma2/9gzZsZIMVy\n/NhMyK0crjvLeheZdZ2mEFqDAOYmP4JVZHkHZDC1ZDm4UnfUiO5lJa+Jmow5\nELLpSyHuYtaD8thGVHh2qcSfNIaMYMpAJOjjrQv9/aFEpZq+Ar0=\n|ba813d3fafa33a0edd77d968d6ba89e406a7ck1eemn5b042be0fab053723rtyu",
              retry: 'false',
              partner_params: partner_params,
              timestamp: 1_562_938_446,
              file_name: 'selfie.zip',
              smile_client_id: partner_id,
              callback_url: '',
              userData: {
                isVerifiedProcess: false,
                name: '',
                fbUserID: '',
                firstName: 'Bill',
                lastName: '',
                gender: '',
                email: '',
                phone: '',
                countryCode: '+',
                countryName: ''
              }
            },
            id_info: id_info,
            images: connection.send(:configure_image_payload),
            server_information: {
              'upload_url' => 'https://some_url/selfie.zip',
              'smile_job_id' => '0000000549',
              'camera_config' => 'null',
              'code' => '2202'
            }
          }
        end

        let(:zip_up_file) { connection.send(:zip_up_file, info_json_v2) }

        it 'contains the necessary files in the zip' do
          zip_up_file.rewind
          file = zip_up_file.read
          expect(file).to include('info.json')
          expect(file).to include('selfie.jpg')
          expect(file).not_to include('id_image.jpg')
        end
      end
    end

    describe '#upload_file' do
      let(:url) { 'www.upload_zip.com' }
      let(:info_json) { {} }
      let(:smile_job_id) { '0000000583' }

      context 'when successful' do
        before do
          # allow(IO).to receive(:read).with('./spec/fixtures/selfie.jpg').and_return('')
          # allow(IO).to receive(:read).with('./tmp/id_image.jpg').and_return('')
          connection.instance_variable_set('@images', images)
        end

        it 'returns a json object if the file upload is a success and return_job_status is false' do
          typhoeus_response = Typhoeus::Response.new(code: 200)
          Typhoeus.stub(url).and_return(typhoeus_response)

          connection.instance_variable_set('@options', options)
          expect(connection.send(:upload_file, url, info_json, smile_job_id))
            .to eq({ success: true, smile_job_id: smile_job_id }.to_json)
        end
      end

      context 'when unsuccessful' do
        before do
          # allow(IO).to receive(:read).with('./spec/fixtures/selfie.jpg').and_return('')
          # allow(IO).to receive(:read).with('./tmp/id_image.jpg').and_return('')
          connection.instance_variable_set('@options', options)
          connection.instance_variable_set('@images', images)
        end

        it 'returns the correct message if the response timed out' do
          typhoeus_response = Typhoeus::Response.new(code: 512, body: 'Some error')
          Typhoeus.stub(url).and_return(typhoeus_response)

          expect { connection.send(:upload_file, url, info_json, smile_job_id) }.to raise_error(RuntimeError)
        end

        it 'returns the correct message if we could not get an http response' do
          typhoeus_response = Typhoeus::Response.new(code: 0, body: 'Some error')
          Typhoeus.stub(url).and_return(typhoeus_response)

          expect { connection.send(:upload_file, url, info_json, smile_job_id) }.to raise_error(RuntimeError)
        end

        it 'returns the correct message if we received a non-successful http response' do
          typhoeus_response = Typhoeus::Response.new(code: 403, body: 'Some error')
          Typhoeus.stub(url).and_return(typhoeus_response)

          expect { connection.send(:upload_file, url, info_json, smile_job_id) }.to raise_error(RuntimeError)
        end
      end
    end

    describe '#query_job_status' do
      before do
        connection.instance_variable_set('@partner_params', partner_params)
        connection.instance_variable_set('@options', options.merge(optional_callback: 'https://zombo.com'))
        connection.instance_variable_set('@api_key', api_key)
        connection.instance_variable_set('@partner_id', partner_id)
        connection.instance_variable_set('@utilies_connection',
                                         SmileIdentityCore::Utilities.new(partner_id, api_key, sid_server))

        def connection.sleep(n)
          # TODO: This isn't ideal, but it's a way to speed up these specs.
          # #query_job_status sleeps as it retries, which adds ~8 seconds to this spec run.
          # Monkeypatching sleep on the connection object here no-ops it so it goes faster.
          # Don't believe me? Uncomment:
          # puts "sleep for #{n}!"
        end
      end

      it 'returns the response if job_complete is true' do
        # allow(IO).to receive(:read).with('./spec/fixtures/selfie.jpg').and_return('')
        # allow(IO).to receive(:read).with('./tmp/id_image.jpg').and_return('')

       # we create a job request first before querying for status 
        VCR.use_cassette('webapi_verification_with_job_complete', preserve_exact_body_bytes: true) do
          connection.submit_job(partner_params, images, id_info, options.merge(optional_callback: 'https://zombo.com', return_job_status: true))
        end
        
        VCR.use_cassette('webapi_query_job_status_job_complete') do |cassette|
          current_time = cassette.originally_recorded_at || Time.now
          Timecop.freeze(current_time) do
            response = connection.send(:query_job_status)
            expect(response['code']).to eq('2302')
          end
        end
      end

      it 'returns the response if the counter is 20' do
        # allow(IO).to receive(:read).with('./spec/fixtures/selfie.jpg').and_return('')
        # allow(IO).to receive(:read).with('./tmp/id_image.jpg').and_return('')

       # we create a job request first before querying for status 
        VCR.use_cassette('webapi_verification_with_counter', preserve_exact_body_bytes: true) do
          connection.submit_job(partner_params, images, id_info, options.merge(optional_callback: 'https://zombo.com', return_job_status: true))
        end
        
        VCR.use_cassette('webapi_query_job_status_with_counter') do |cassette|
          current_time = cassette.originally_recorded_at || Time.now
          Timecop.freeze(current_time) do
            response = connection.send(:query_job_status, 19)

            expect(response['code']).to eq('2302')
            expect(Time.parse(response['timestamp'])).to be_within(10).of current_time
          end
        end
      end

      it 'increments the counter if the counter is less than 20 and job_complete is not true' do
        # NOTE: to give more thought
      end
    end

    describe '#get_job_status' do

      before do
        connection.instance_variable_set('@partner_params', partner_params)
        connection.instance_variable_set('@options', options.merge(optional_callback: 'https://zombo.com'))
        connection.instance_variable_set('@api_key', api_key)
        connection.instance_variable_set('@partner_id', partner_id)
        connection.instance_variable_set('@utilies_connection',
                                         SmileIdentityCore::Utilities.new(partner_id, api_key, sid_server))
      end

      it 'returns the response for job status' do
        # allow(IO).to receive(:read).with('./spec/fixtures/selfie.jpg').and_return('')
        # allow(IO).to receive(:read).with('./tmp/id_image.jpg').and_return('')

       # we create a job request first before querying for status 
       VCR.use_cassette('webapi_verification_with_return_job_status', preserve_exact_body_bytes: true) do
          connection.submit_job(partner_params, images, id_info\
            , options.merge(optional_callback: 'https://zombo.com', return_job_status: true))
        end

        VCR.use_cassette('webapi_verification_get_job_status') do |cassette|
          current_time = cassette.originally_recorded_at || Time.now
          Timecop.freeze(current_time) do
            response = connection.send(:get_job_status, partner_params, options)

            expect(response['code']).to eq('2302')
          end
        end
      end
    end

    describe 'get_web_token' do
      # let(:user_id) { '1' }
      # let(:job_id) { '1' }
      let(:product) { 'ekyc_smartselfie' }

      let(:callback_url) { default_callback }
      let(:request_params) do
        partner_params.merge(product: product, callback_url: callback_url)
      end

      let(:url) { 'https://testapi.smileidentity.com/v1/token' }
      let(:response_body) { nil }
      let(:response_code) { 200 }
      let(:typhoeus_response) { Typhoeus::Response.new(code: response_code, body: response_body) }

      it 'ensures request params are present' do
        expect do
          connection.get_web_token(nil)
        end.to raise_error(ArgumentError, 'Please ensure that you send through request params')
      end

      it 'ensures request params is a hash' do
        expect { connection.get_web_token(1) }.to raise_error(ArgumentError, 'Request params needs to be an object')
      end

      context "when callback_url not set on request_params or #{described_class}" do
        let(:default_callback) { nil }

        it 'raises an ArgumentError' do
          expect do
            connection.get_web_token(request_params)
          end.to raise_error(ArgumentError, 'callback_url is required to get a web token')
        end
      end

      context "when callback_url is an empty string on request_params and #{described_class}" do
        let(:default_callback) { '' }

        it 'raises an ArgumentError' do
          expect do
            connection.get_web_token(request_params)
          end.to raise_error(ArgumentError, 'callback_url is required to get a web token')
        end
      end

      context 'when request_params is passed without values' do
        let(:user_id) { nil }

        it 'raises ArgumentError with missing keys if request params is an empty hash' do
          expect do
            connection.get_web_token({})
          end.to raise_error(ArgumentError, 'user_id, job_id, product are required to get a web token')
        end

        it 'raises ArgumentError with missing keys if request params has nil values' do
          expect do
            connection.get_web_token(request_params.merge(user_id: nil))
          end.to raise_error(ArgumentError, 'user_id is required to get a web token')
        end
      end

      context 'successful http request' do
        let(:response_body) { { token: 'xxx' } }
        let(:security) { { timestamp: 'time', signature: 'key' } }
        let(:version) { { source_sdk: SmileIdentityCore::SOURCE_SDK, source_sdk_version: SmileIdentityCore::VERSION } }

        before do
          allow_any_instance_of(described_class).to receive(:request_security).and_return(security)
        end

        it 'sends a signature, timestamp and partner_id as part of request' do
          request_body = request_params
          headers = { 'Content-Type' => 'application/json' }

          VCR.use_cassette('webapi_verification_web_token') do |cassette|
            current_time = cassette.originally_recorded_at || Time.now
            Timecop.freeze(current_time) do
              request_body.merge!(SmileIdentityCore::Signature.new(partner_id,
                                                                   api_key).generate_signature(Time.now.to_s))
                          .merge!(
                            { partner_id: partner_id,
                              source_sdk: SmileIdentityCore::SOURCE_SDK,
                              source_sdk_version: SmileIdentityCore::VERSION }
                          )

              expect(Typhoeus).to receive(:post).with(url,
                                                      { body: request_body.to_json,
                                                        headers: headers}).and_return(typhoeus_response)
              connection.get_web_token(request_params)
            end
          end
        end

        it 'returns a token' do
          VCR.use_cassette('webapi_verification_web_token') do
            connection.instance_variable_set(:@partner_id, partner_id)
            token_response = connection.get_web_token(request_params)
            parsed_reponse = JSON.parse(token_response)
            expect(parsed_reponse['success']).to be_truthy
          end
        end
      end

      context 'when http request timed out' do
        let(:response_code) { 522 }

        it 'raises a RuntimeError' do
          VCR.use_cassette('webapi_verification_web_token_error') do
            expect { connection.get_web_token(request_params.merge(product: '123')) }.to raise_error(RuntimeError)
          end
        end
      end

      context 'when http response code is zero' do
        let(:response_code) { 0 }

        it 'raises a RuntimeError' do
          VCR.use_cassette('webapi_verification_web_token_error') do
            expect { connection.get_web_token(request_params.merge(product: '123')) }.to raise_error(RuntimeError)
          end
        end
      end

      context 'when http response code is not 200' do
        let(:response_code) { 400 }

        it 'raises a RuntimeError' do
          VCR.use_cassette('webapi_verification_web_token_error') do
            expect { connection.get_web_token(request_params.merge(product: '123')) }.to raise_error(RuntimeError)
          end
        end
      end
    end
  end
end
