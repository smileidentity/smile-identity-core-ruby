# frozen_string_literal: true

RSpec.describe SmileIdentityCore::WebApi do
  let(:partner_id) { '001' }
  let(:default_callback) { 'www.default_callback.com' }
  let(:api_key) { Base64.encode64(OpenSSL::PKey::RSA.new(1024).public_key.to_pem) }
  let(:sid_server) { SmileIdentityCore::ENV::TEST }

  let(:connection) { described_class.new(partner_id, default_callback, api_key, sid_server) }

  let(:partner_params) do
    {
      user_id: '1',
      job_id: '2',
      job_type: SmileIdentityCore::JobType::BIOMETRIC_KYC
    }
  end

  let(:images) do
    [
      {
        image_type_id: SmileIdentityCore::ImageType::SELFIE_IMAGE_FILE,
        image: './tmp/selfie.png'
      },
      {
        image_type_id: SmileIdentityCore::ImageType::ID_CARD_IMAGE_FILE,
        image: './tmp/id_image.png'
      }
    ]
  end

  let(:images_v2) do
    [
      {
        image_type_id: SmileIdentityCore::ImageType::SELFIE_IMAGE_FILE,
        image: './tmp/selfie.png'
      },
      {
        image_type_id: SmileIdentityCore::ImageType::ID_CARD_BACK_IMAGE_BASE64,
        image: '/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBxITEhUSEhMVFRUXFxcWFRUVFRUVFRgWFRUXFhcW='
      }

    ]
  end

  let(:id_info) do
    {
      first_name: 'John',
      last_name: 'Doe',
      middle_name: '',
      country: 'NG',
      id_type: 'BVN',
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

  let(:timestamp) { Time.now.to_i }

  context 'when the public methods behave correctly' do
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
              image_type_id: SmileIdentityCore::ImageType::ID_CARD_BACK_IMAGE_FILE,
              image_path: './tmp/id_image.png'
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

        it 'allows leaving id_number and id_type fields empty in id_info for JT6' do
          connection.instance_variable_set('@url', 'https://www.example.com')
          response_upload_url = 'https://smile-uploads-somewhere.amazonaws.com/videos/a_signed_url'
          body = {
            'upload_url' => response_upload_url,
            'ref_id' => '125-0000000583-s8fqo7ju2ji2u32hhu4us11bq3yhww',
            'smile_job_id' => '0000000583',
            'camera_config' => 'null',
            'code' => '2202'
          }.to_json
          Typhoeus.stub('https://www.example.com/upload').and_return(Typhoeus::Response.new(code: 200, body: body))
          allow(IO).to receive(:read).with('./tmp/selfie.png').and_return('')
          allow(IO).to receive(:read).with('./tmp/id_image.png').and_return('')
          Typhoeus.stub(response_upload_url).and_return(Typhoeus::Response.new(code: 200))

          amended_partner_params = partner_params.merge({
            job_type: SmileIdentityCore::JobType::DOCUMENT_VERIFICATION
          })
          %i[id_number id_type].each do |key|
            amended_id_info = id_info.merge(key => '')
            expect { connection.submit_job(amended_partner_params, images, amended_id_info, options) }
              .not_to raise_error
          end
        end

        it 'country field in id_info is required for JT6' do
          amended_id_info = id_info.merge('country' => '')
          amended_partner_params = partner_params.merge({
            job_type: SmileIdentityCore::JobType::DOCUMENT_VERIFICATION
          })
          expect { connection.submit_job(amended_partner_params, images, amended_id_info, options) }
            .to raise_error(ArgumentError, 'Please make sure that country is included in the id_info')
        end

        it 'checks that return_job_status is a boolean' do
          expect { connection.submit_job(partner_params, images, id_info, options.merge(return_job_status: 'false')) }
            .to raise_error(ArgumentError, 'return_job_status needs to be a boolean')
        end
      end

      it 'updates the callback_url when optional_callback is defined' do
        # This is really about setting config...from options to an ivar. It's confused because all the other
        # config is good, so we fire off two HTTP requests, and we need to mock them.

        # Set everything up:
        connection.instance_variable_set('@url', 'https://www.example.com')

        response_upload_url = 'https://smile-uploads-somewhere.amazonaws.com/videos/a_signed_url'
        body = {
          'upload_url' => response_upload_url,
          'ref_id' => '125-0000000583-s8fqo7ju2ji2u32hhu4us11bq3yhww',
          'smile_job_id' => '0000000583',
          'camera_config' => 'null',
          'code' => '2202'
        }.to_json

        Typhoeus.stub('https://www.example.com/upload').and_return(Typhoeus::Response.new(code: 200, body: body))

        allow(IO).to receive(:read).with('./tmp/selfie.png').and_return('')
        allow(IO).to receive(:read).with('./tmp/id_image.png').and_return('')

        Typhoeus.stub(response_upload_url).and_return(Typhoeus::Response.new(code: 200))

        # Test the preconditions! `default_callback` is what `connection` was instantiated with.
        expect(connection.instance_variable_get(:@callback_url)).to eq(default_callback)

        # Run the code, passing the `optional_callback` option:
        connection.submit_job(partner_params, images, id_info, options.merge(optional_callback: 'https://zombo.com'))

        # Make sure @callback_url gets set:
        expect(connection.instance_variable_get(:@callback_url)).to eq('https://zombo.com')
      end

      [5, 7].each do |job_type|
        it "ensures that IDApi is called when job id is #{job_type}" do
          body = {
            "JSONVersion": '1.0.0',
            "SmileJobID": '0000001096'
          }
          response = Typhoeus::Response.new(code: 200, body: body)
          Typhoeus.stub('https://testapi.smileidentity.com/v1/business_verification').and_return(response)
          Typhoeus.stub('https://testapi.smileidentity.com/v1/id_verification').and_return(response)

          business_info = { country: 'NG', business_type: 'co', id_type: 'BUSINESS_REGISTRATION', id_number: '0000000' }
          instance = instance_double(SmileIdentityCore::IDApi)
          class_double = class_double(SmileIdentityCore::IDApi).as_stubbed_const

          allow(class_double).to receive(:new).and_return(instance)
          allow(instance).to receive(:submit_job).and_return(body)

          connection.submit_job(partner_params.merge(job_type: job_type), images, id_info.merge(business_info),
                                options.merge(optional_callback: 'https://zombo.com'))
          expect(instance).to have_received(:submit_job).once
        end
      end

      # xit 'ensures that we only except a png or jpg' do
      #   # check the image_path
      # end
    end
  end

  context 'when the private methods behave correctly' do
    # NOTE: In this gem, we do test the private methods because we have split up a lot of
    # the logic into private methods that feed into the public method.
    let(:options_with_job_status_true) do
      options.merge(return_job_status: true)
    end

    describe '#validate_return_data' do
      it 'validates that data is returned via the callback or job_status' do
        connection.instance_variable_set('@callback_url', '')
        connection.instance_variable_set('@options', options_with_job_status_true)
        expect { connection.send(:validate_return_data) }.not_to raise_error

        connection.instance_variable_set('@options', options)
        expect { connection.send(:validate_return_data) }
          .to raise_error(ArgumentError,
                          'Please choose to either get your response via the callback or job status query')

        connection.instance_variable_set('@options', options_with_job_status_true)
        connection.instance_variable_set('@callback_url', default_callback)
        expect { connection.send(:validate_return_data) }.not_to raise_error
      end
    end

    describe '#validate_enroll_with_id' do
      before do
        connection.instance_variable_set('@images', [
                                           {
                                             image_type_id: SmileIdentityCore::ImageType::SELFIE_IMAGE_FILE,
                                             image: './tmp/selfie1.png'
                                           },
                                           {
                                             image_type_id: SmileIdentityCore::ImageType::SELFIE_IMAGE_FILE,
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
      let(:url) { 'https://www.example.com' }

      before do
        connection.instance_variable_set('@url', url)
      end

      it 'returns a json object if it runs successfully' do
        response_upload_url = 'https://some-url/selfie.zip'
        response_smile_job_id = '0000000583'
        body = {
          'upload_url' => response_upload_url,
          'ref_id' => '125-0000000583-s8fqo7ju2ji2u32hhu4us11bq3yhww',
          'smile_job_id' => response_smile_job_id,
          'camera_config' => 'null',
          'code' => '2202'
        }.to_json

        Typhoeus.stub("#{url}/upload").and_return(Typhoeus::Response.new(code: 200, body: body))

        allow(IO).to receive(:read).with('./tmp/selfie.png').and_return('')
        allow(IO).to receive(:read).with('./tmp/id_image.png').and_return('')

        connection.instance_variable_set('@images', images)
        connection.instance_variable_set('@options', options)

        Typhoeus.stub(JSON.parse(body)['upload_url']).and_return(Typhoeus::Response.new(code: 200))

        setup_requests = connection.send(:setup_requests)
        expect(JSON.parse(setup_requests)).to eq('success' => true, 'smile_job_id' => response_smile_job_id)
      end

      it 'returns the correct message if we could not get an http response' do
        response = Typhoeus::Response.new(code: 0, body: 'Some error')
        Typhoeus.stub("#{url}/upload").and_return(response)

        expect { connection.send(:setup_requests) }.to raise_error(RuntimeError)
      end

      it 'returns the correct message if we received a non-successful http response' do
        response = Typhoeus::Response.new(code: 403, body: 'Some error')
        Typhoeus.stub("#{url}/upload").and_return(response)

        expect { connection.send(:setup_requests) }.to raise_error(RuntimeError)
      end

      it 'returns the correct message if there is a timeout' do
        # find the correct code
        response = Typhoeus::Response.new(code: 512, body: 'Some error')
        Typhoeus.stub("#{url}/upload").and_return(response)

        expect { connection.send(:setup_requests) }.to raise_error(RuntimeError)
      end
    end

    describe '#configure_info_json' do
      # NOTE: we can perhaps still test that the instance variables that are set in
      # the payload are the ones set in the connection
      before do
        connection.instance_variable_set('@id_info', 'a value for @id_info')
        connection.instance_variable_set('@images', images)
      end

      let(:configure_info_json) { connection.send(:configure_info_json, 'the server information url') }

      it 'includes the images on the root level' do
        expect(configure_info_json.fetch(:images)).to be_kind_of(Array)
      end

      it 'includes the relevant id_info on the root level' do
        expect(configure_info_json.fetch(:id_info)).to eq('a value for @id_info')
      end

      it 'includes the relevant server_information on the root level' do
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
          api_version = connection.send(:configure_info_json,
                                        'the server information url')[:package_information][:apiVersion]
          expect(api_version[:buildNumber]).to be(0)
          expect(api_version[:majorVersion]).to be(2)
          expect(api_version[:minorVersion]).to be(0)
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

      it 'correctly sets the image type value to SmileIdentityCore::ImageType::SELFIE_IMAGE_FILE' do
        expect(connection.send(:configure_image_payload)[0][:image_type_id]).to eq(images_v2[0][:image_type_id])
      end

      it 'correctly sets the image type value to SmileIdentityCore::ImageType::ID_CARD_BACK_IMAGE_BASE64' do
        expect(connection.send(:configure_image_payload)[1][:image_type_id]).to eq(images_v2[1][:image_type_id])
      end

      it 'correctly sets the image value' do
        expect(connection.send(:configure_image_payload)[1][:image]).to eq(images_v2[1][:image])
      end

      it 'correctly sets the file_name value' do
        expect(connection.send(:configure_image_payload)[0][:file_name]).to eq(File.basename(images_v2[0][:image]))
      end
    end

    describe '#zip_up_file' do
      before do
        allow(IO).to receive(:read).with('./tmp/selfie.png').and_return('')
        allow(IO).to receive(:read).with('./tmp/id_image.png').and_return('')
        connection.instance_variable_set('@images', images)
      end

      let(:info_json) do
        {
          package_information: {
            apiVersion: {
              buildNumber: 0,
              majorVersion: 2,
              minorVersion: 0
            }
          },
          misc_information: {
            signature: "zWzSzfvXzvN0MdPHtW78a9w3Zlyy7k9UY6Li7pikHniTeuma2/9gzZsZIMVy\n/NhMyK0crjvLeheZ\
            dZ2mEFqDAOYmP4JVZHkHZDC1ZDm4UnfUiO5lJa+Jmow5\nELLpSyJzHVaD8thGVHh2qcSfNIaMYMpAJOjjrQv9/aFE\
            pZq+Ar0=\n|ba813d3fafa33a0edd77d968d6ba89e406a7ck1eemn5b042be0fab053723rtyu",
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
        it 'contains the necessary info.json file in the zip' do
          zip_up_file.rewind
          file = zip_up_file.read
          expect(file).to include('info.json')
        end

        it 'contains the necessary selfie.png in the zip' do
          zip_up_file.rewind
          file = zip_up_file.read
          expect(file).to include('selfie.png')
        end

        it 'contains the necessary id_image.png in the zip' do
          zip_up_file.rewind
          file = zip_up_file.read
          expect(file).to include('id_image.png')
        end
      end

      context 'with a combination of physical and base 64 files' do
        before do
          allow(IO).to receive(:read).with('./tmp/selfie.png').and_return('')
          allow(IO).to receive(:read).with('./tmp/id_image.png').and_return('')
          connection.instance_variable_set('@images', images_v2)
        end

        let(:info_json_v2) do
          {
            package_information: {
              apiVersion: {
                buildNumber: 0,
                majorVersion: 2,
                minorVersion: 0
              }
            },
            misc_information: {
              signature: "zWzSzfvXzvN0MdPHtW7879w3Zlyy7k9UY6Li7pikHniTUuma2/9gzZsZIMVy\n/NhMyK0crjvLe\
              heZdZ2mEFqDAOYmP4JVZHkHZDC1ZDm4UnfUiO5lJa+Jmow5\nELLpSyHuYtaD8thGVHh2qcSfNIaMYMpAJOjjr\
              Qv9/aFEpZq+Ar0=\n|ba813d3fafa33a0edd77d968d6ba89e406a7ck1eemn5b042be0fab053723rtyu",
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

        it 'contains the necessary info.json file in the zip' do
          zip_up_file.rewind
          file = zip_up_file.read
          expect(file).to include('info.json')
        end

        it 'contains the necessary selfie.png file in the zip' do
          zip_up_file.rewind
          file = zip_up_file.read
          expect(file).to include('selfie.png')
        end

        it 'contains the necessary id_image.png file in the zip' do
          zip_up_file.rewind
          file = zip_up_file.read
          expect(file).not_to include('id_image.png')
        end
      end
    end

    context 'when #upload_file is successful' do
      let(:url) { 'www.upload_zip.com' }
      let(:info_json) { {} }
      let(:smile_job_id) { '0000000583' }

      before do
        allow(IO).to receive(:read).with('./tmp/selfie.png').and_return('')
        allow(IO).to receive(:read).with('./tmp/id_image.png').and_return('')
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

    context 'when #upload_file is unsuccessful' do
      before do
        allow(IO).to receive(:read).with('./tmp/selfie.png').and_return('')
        allow(IO).to receive(:read).with('./tmp/id_image.png').and_return('')
        connection.instance_variable_set('@options', options)
        connection.instance_variable_set('@images', images)
      end

      it 'returns the correct message if the response timed out' do
        typhoeus_response = Typhoeus::Response.new(code: 512, body: 'Some error')
        Typhoeus.stub(@url).and_return(typhoeus_response)

        expect { connection.send(:upload_file, @url, @info_json, @smile_job_id) }.to raise_error(RuntimeError)
      end

      it 'returns the correct message if we could not get an http response' do
        typhoeus_response = Typhoeus::Response.new(code: 0, body: 'Some error')
        Typhoeus.stub(@url).and_return(typhoeus_response)

        expect { connection.send(:upload_file, @url, @info_json, @smile_job_id) }.to raise_error(RuntimeError)
      end

      it 'returns the correct message if we received a non-successful http response' do
        typhoeus_response = Typhoeus::Response.new(code: 403, body: 'Some error')
        Typhoeus.stub(@url).and_return(typhoeus_response)

        expect { connection.send(:upload_file, @url, @info_json, @smile_job_id) }.to raise_error(RuntimeError)
      end
    end

    describe '#query_job_status' do
      let(:url) { 'https://some_server.com/dev01' }
      let(:rsa) { OpenSSL::PKey::RSA.new(1024) }
      let(:api_key) { 'API_KEY' }
      let(:timestamp) { Time.now.to_i }

      before do
        connection.instance_variable_set('@partner_params', {
                                           user_id: '1',
                                           job_id: '2',
                                           job_type: 1
                                         })
        connection.instance_variable_set('@url', url)
        connection.instance_variable_set('@options', options)
        connection.instance_variable_set('@api_key', api_key)
        connection.instance_variable_set('@partner_id', partner_id)
        connection.instance_variable_set('@utilies_connection',
                                         SmileIdentityCore::Utilities.new(partner_id, api_key, sid_server))

        hmac = OpenSSL::HMAC.new(api_key, 'sha256')
        hmac.update(timestamp.to_s)
        hmac.update(partner_id)
        hmac.update('sid_request')
        @signature = Base64.strict_encode64(hmac.digest)

        def connection.sleep(time_is_seconds)
          # TODO: This isn't ideal, but it's a way to speed up these specs.
          # #query_job_status sleeps as it retries, which adds ~8 seconds to this spec run.
          # Monkeypatching sleep on the connection object here no-ops it so it goes faster.
          # Don't believe me? Uncomment:
          # puts "sleep for #{n}!"
        end
      end

      it 'returns the response if job_complete is true' do
        body = {
          timestamp: timestamp.to_s,
          signature: @signature.to_s,
          job_complete: true,
          job_success: false,
          code: '2302',
          success: true,
          smile_job_id: '123',
          source_sdk: instance_of(String),
          source_sdk_version: instance_of(String)
        }.to_json

        typhoeus_response = Typhoeus::Response.new(code: 200, body: body.to_s)
        Typhoeus.stub(@url).and_return(typhoeus_response)

        expect(connection.send(:query_job_status)).to eq(JSON.parse(body.to_s))
      end

      it 'returns the response if the counter is 20' do
        body = {
          timestamp: timestamp.to_s,
          signature: @signature.to_s,
          job_complete: false,
          job_success: false,
          code: '2302',
          success: true,
          smile_job_id: '123',
          source_sdk: SmileIdentityCore::SOURCE_SDK,
          source_sdk_version: SmileIdentityCore::VERSION
        }.to_json

        typhoeus_response = Typhoeus::Response.new(code: 200, body: body.to_s)
        Typhoeus.stub(@url).and_return(typhoeus_response)

        expect(connection.send(:query_job_status, 19)).to eq(JSON.parse(body.to_s))
      end

      it 'increments the counter if the counter is less than 20 and job_complete is not true' do
        # NOTE: to give more thought
      end
    end

    describe 'get_web_token' do
      let(:user_id) { '1' }
      let(:job_id) { '1' }
      let(:product) { 'ekyc_smartselfie' }

      let(:callback_url) { default_callback }
      let(:request_params) do
        {
          user_id: user_id,
          job_id: job_id,
          product: product,
          callback_url: callback_url
        }
      end

      let(:url) { 'https://testapi.smileidentity.com/v1/token' }
      let(:response_body) { nil }
      let(:response_code) { 200 }
      let(:typhoeus_response) { Typhoeus::Response.new(code: response_code, body: response_body) }

      before do
        Typhoeus.stub(url).and_return(typhoeus_response)
        # connection = described_class.new(partner_id, default_callback, api_key, sid_server)
      end

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
            connection.get_web_token(request_params)
          end.to raise_error(ArgumentError, 'user_id is required to get a web token')
        end
      end

      context 'when http request is successful' do
        let(:response_body) { { token: 'xxx' } }
        let(:security) { { timestamp: 'time', signature: 'key' } }
        let(:version) { { source_sdk: SmileIdentityCore::SOURCE_SDK, source_sdk_version: SmileIdentityCore::VERSION } }

        before do
          instance = instance_double(SmileIdentityCore::Signature)
          allow(SmileIdentityCore::Signature).to receive(:new).and_return(instance)
          allow(instance).to receive(:generate_signature).and_return(security)
        end

        it 'sends a signature, timestamp and partner_id as part of request' do
          request_body = request_params.merge(security).merge(partner_id: partner_id).merge(version).to_json
          headers = { 'Content-Type' => 'application/json' }

          allow(Typhoeus).to receive(:post).with(url, { body: request_body, headers: headers })
                                           .and_return(typhoeus_response)

          connection.get_web_token(request_params)
        end

        it 'returns a token' do
          expect(connection.get_web_token(request_params)).to eq({ token: 'xxx' })
        end
      end

      context 'when http request timed out' do
        let(:response_code) { 522 }

        it 'raises a RuntimeError' do
          expect { connection.get_web_token(request_params) }.to raise_error(RuntimeError)
        end
      end

      context 'when http response code is zero' do
        let(:response_code) { 0 }

        it 'raises a RuntimeError' do
          expect { connection.get_web_token(request_params) }.to raise_error(RuntimeError)
        end
      end

      context 'when http response code is not 200' do
        let(:response_code) { 400 }

        it 'raises a RuntimeError' do
          expect { connection.get_web_token(request_params) }.to raise_error(RuntimeError)
        end
      end
    end
  end
end
