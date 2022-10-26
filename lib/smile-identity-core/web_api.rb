# frozen_string_literal: true

require 'json'
require 'tempfile'
require 'base64'
require 'openssl'
require 'uri'

require 'typhoeus'
require 'zip'

module SmileIdentityCore
  class WebApi
    def initialize(partner_id, default_callback, api_key, sid_server)
      @partner_id = partner_id.to_s
      @callback_url = default_callback
      @api_key = api_key

      @sid_server = sid_server
      if sid_server !~ URI::DEFAULT_PARSER.make_regexp
        sid_server_mapping = {
          0 => 'https://testapi.smileidentity.com/v1',
          1 => 'https://api.smileidentity.com/v1'
        }
        @url = sid_server_mapping[sid_server.to_i]
      else
        @url = sid_server
      end
    end

    def submit_job(partner_params, images, id_info, options)
      self.partner_params = symbolize_keys partner_params
      if @partner_params[:job_type].to_i == 5
        return SmileIdentityCore::IDApi.new(@partner_id, @api_key, @sid_server).submit_job(partner_params, id_info)
      end

      self.images = images
      self.id_info = symbolize_keys id_info
      self.options = symbolize_keys options

      @callback_url = @options[:optional_callback] if @options[:optional_callback]&.length&.positive?

      validate_enroll_with_id if @partner_params[:job_type].to_i == 1

      validate_return_data

      setup_requests
    end

    def get_job_status(partner_params, options)
      partner_params = symbolize_keys partner_params
      @timestamp = Time.now.to_i

      user_id = partner_params[:user_id]
      job_id = partner_params[:job_id]

      utilities = SmileIdentityCore::Utilities.new(@partner_id, @api_key, @sid_server)
      utilities.get_job_status(user_id, job_id, options)
    end

    def partner_params=(partner_params)
      raise ArgumentError, 'Please ensure that you send through partner params' if partner_params.nil?

      raise ArgumentError, 'Partner params needs to be a hash' unless partner_params.is_a?(Hash)

      %i[user_id job_id job_type].each do |key|
        next if partner_params[key] && !partner_params[key].nil? && !(if partner_params[key].is_a?(String)
                                                                        partner_params[key].empty?
                                                                      end)

        raise ArgumentError, "Please make sure that #{key} is included in the partner params"
      end

      @partner_params = partner_params
    end

    def images=(images)
      raise ArgumentError, 'Please ensure that you send through image details' if images.nil?

      raise ArgumentError, 'Image details needs to be an array' unless images.is_a?(Array)

      # all job types require atleast a selfie
      if images.length.zero? || images.none? { |h| (h[:image_type_id]).zero? || h[:image_type_id] == 2 }
        raise ArgumentError, 'You need to send through at least one selfie image'
      end

      @images = images.map { |image| symbolize_keys image }
    end

    def id_info=(id_info)
      updated_id_info = id_info

      updated_id_info = {} if updated_id_info.nil?

      # if it doesnt exist, set it false
      updated_id_info[:entered] = 'false' if !updated_id_info.key?(:entered) || id_info[:entered].empty?

      # if it's a boolean
      updated_id_info[:entered] = id_info[:entered].to_s if !updated_id_info[:entered].nil? == updated_id_info[:entered]

      if updated_id_info[:entered] && updated_id_info[:entered] == 'true'
        %i[country id_type id_number].each do |key|
          unless id_info[key] && !id_info[key].nil? && !id_info[key].empty?
            raise ArgumentError, "Please make sure that #{key} is included in the id_info"
          end
        end
      end

      @id_info = updated_id_info
    end

    def options=(options)
      updated_options = options || {}

      updated_options[:optional_callback] = check_string(:optional_callback, options)
      updated_options[:return_job_status] = check_boolean(:return_job_status, options)
      updated_options[:return_image_links] = check_boolean(:return_image_links, options)
      updated_options[:return_history] = check_boolean(:return_history, options)

      @options = updated_options
    end

    def get_web_token(request_params)
      raise ArgumentError, 'Please ensure that you send through request params' if request_params.nil?
      raise ArgumentError, 'Request params needs to be an object' unless request_params.is_a?(Hash)

      callback_url = request_params[:callback_url] || @callback_url
      request_params[:callback_url] = callback_url

      keys = %i[user_id job_id product callback_url]
      blank_keys = get_blank_keys(keys, request_params)
      error_message = "#{blank_keys.join(', ')} #{blank_keys.length > 1 ? 'are' : 'is'} required to get a web token"
      raise ArgumentError, error_message unless blank_keys.empty?

      request_web_token(request_params)
    end

    private

    def request_web_token(request_params)
      request_params
        .merge(SmileIdentityCore::Signature.new(@partner_id, @api_key).generate_signature(Time.now.to_s))
        .merge!(
          { partner_id: @partner_id,
            source_sdk: SmileIdentityCore::SOURCE_SDK,
            source_sdk_version: SmileIdentityCore::VERSION }
        )
      url = "#{@url}/token"

      response = Typhoeus.post(
        url,
        headers: { 'Content-Type' => 'application/json' },
        body: request_params.to_json
      )

      return response.body if response.code == 200

      raise "#{response.code}: #{response.body}"
    end

    def symbolize_keys(params)
      params.is_a?(Hash) ? params.transform_keys(&:to_sym) : params
    end

    def validate_return_data
      if (!@callback_url || @callback_url.empty?) && !@options[:return_job_status]
        raise ArgumentError, 'Please choose to either get your response via the callback or job status query'
      end
    end

    def validate_enroll_with_id
      if (@images.none? { |h| h[:image_type_id] == 1 || h[:image_type_id] == 3 }) && @id_info[:entered] != 'true'
        raise ArgumentError, 'You are attempting to complete a job type 1 without providing an id card image or id info'
      end
    end

    def check_boolean(key, obj)
      return false if !obj || !obj[key]

      raise ArgumentError, "#{key} needs to be a boolean" if !obj[key].nil? != obj[key]

      obj[key]
    end

    def check_string(key, obj)
      if !obj || !obj[key]
        ''
      else
        obj[key]
      end
    end

    def blank?(obj, key)
      return obj[key].empty? if obj[key].respond_to?(:empty?)

      obj[key].nil?
    end

    def get_blank_keys(keys, obj)
      keys.select { |key| blank?(obj, key) }
    end

    def configure_prep_upload_json
      SmileIdentityCore::Signature.new(@partner_id, @api_key).generate_signature(Time.now.to_s).merge(
        file_name: 'selfie.zip',
        smile_client_id: @partner_id,
        partner_params: @partner_params,
        model_parameters: {}, # what is this for
        callback_url: @callback_url,
        source_sdk: SmileIdentityCore::SOURCE_SDK,
        source_sdk_version: SmileIdentityCore::VERSION
      ).to_json
    end

    def setup_requests
      url = "#{@url}/upload"
      request = Typhoeus::Request.new(
        url,
        method: 'POST',
        headers: { 'Content-Type' => 'application/json' },
        body: configure_prep_upload_json
      )

      request.on_complete do |response|
        if response.success?
          # TODO: if/when we sign these responses, verify the signature here and raise if it's off.
          # if updated_options[:signature]
          #   SmileIdentityCore::Signature.new(@partner_id, @api_key).generate_signature(@timestamp)
          # else
          #   SmileIdentityCore::Signature.new(@partner_id, @api_key).generate_sec_key(@timestamp)
          # end

          prep_upload_response = JSON.parse(response.body)
          info_json = configure_info_json(prep_upload_response)

          file_upload_response = upload_file(prep_upload_response['upload_url'], info_json,
                                             prep_upload_response['smile_job_id'])
          return file_upload_response
        end

        raise "#{response.code}: #{response.body}"
      end
      request.run
    end

    def configure_info_json(server_information)
      {
        "package_information": {
          "apiVersion": {
            "buildNumber": 0,
            "majorVersion": 2,
            "minorVersion": 0
          },
          "language": 'ruby'
        },
        "misc_information": SmileIdentityCore::Signature.new(@partner_id, @api_key).generate_signature(Time.now.to_s)
                                                        .merge(
                                                          "retry": 'false',
                                                          "partner_params": @partner_params,
                                                          "file_name": 'selfie.zip', # figure out what to do here
                                                          "smile_client_id": @partner_id,
                                                          "callback_url": @callback_url,
                                                          "userData": { # TO ASK what goes here
                                                            "isVerifiedProcess": false,
                                                            "name": '',
                                                            "fbUserID": '',
                                                            "firstName": 'Bill',
                                                            "lastName": '',
                                                            "gender": '',
                                                            "email": '',
                                                            "phone": '',
                                                            "countryCode": '+',
                                                            "countryName": ''
                                                          }
                                                        ),
        "id_info": @id_info,
        "images": configure_image_payload,
        "server_information": server_information
      }
    end

    def configure_image_payload
      @images.map do |i|
        if image_file?(i[:image_type_id])
          {
            image_type_id: i[:image_type_id],
            image: '',
            file_name: File.basename(i[:image])
          }
        else
          {
            image_type_id: i[:image_type_id],
            image: i[:image],
            file_name: ''
          }
        end
      end
    end

    def image_file?(type)
      type.to_i.zero? || type.to_i == 1
    end

    def zip_up_file(info_json)
      # https://info.michael-simons.eu/2008/01/21/using-rubyzip-to-create-zip-files-on-the-fly/
      Zip::OutputStream.write_buffer do |zos|
        zos.put_next_entry('info.json')
        zos.puts JSON.pretty_generate(info_json)

        if @images.length.positive?
          @images.each do |img|
            if (img[:image_type_id]).zero? || img[:image_type_id] == 1
              zos.put_next_entry(File.basename(img[:image]))
              zos.print IO.read(img[:image])
            end
          end
        end
      end
    end

    def upload_file(url, info_json, smile_job_id)
      file = zip_up_file(info_json)
      file.rewind

      request = Typhoeus::Request.new(
        url,
        method: 'PUT',
        headers: { 'Content-Type' => 'application/zip' },
        body: file.read
      )

      request.on_complete do |response|
        if response.success?
          if @options[:return_job_status]
            @utilies_connection = SmileIdentityCore::Utilities.new(@partner_id, @api_key, @sid_server)
            job_response = query_job_status
            job_response['success'] = true
            job_response['smile_job_id'] = smile_job_id
            return job_response
          else
            return { success: true, smile_job_id: smile_job_id }.to_json
          end
        end
        raise " #{response.code}: #{response.body}"
      end
      request.run
    end

    def query_job_status(counter = 0)
      counter < 4 ? (sleep 2) : (sleep 6)
      counter += 1

      response = @utilies_connection.get_job_status(@partner_params[:user_id], @partner_params[:job_id], @options)

      if response && (response['job_complete'] == true || counter == 20)
        response
      else
        query_job_status(counter)
      end
    end
  end
end
