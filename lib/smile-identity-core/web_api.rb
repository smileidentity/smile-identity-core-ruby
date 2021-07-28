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
      if !(sid_server =~ URI::regexp)
        sid_server_mapping = {
          0 => 'https://3eydmgh10d.execute-api.us-west-2.amazonaws.com/test',
          1 => 'https://la7am6gdm8.execute-api.us-west-2.amazonaws.com/prod'
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
      @timestamp = Time.now

      self.id_info = symbolize_keys id_info
      self.options = symbolize_keys options

      if @options[:optional_callback] && @options[:optional_callback].length > 0
        @callback_url = @options[:optional_callback]
      end

      if @partner_params[:job_type].to_i == 1
        validate_enroll_with_id
      end

      validate_return_data

      return setup_requests
    end

    def get_job_status(partner_params, options)
      partner_params = symbolize_keys partner_params
      @timestamp = Time.now.to_i

      user_id = partner_params[:user_id]
      job_id = partner_params[:job_id]

      utilities = SmileIdentityCore::Utilities.new(@partner_id, @api_key, @sid_server)
      return utilities.get_job_status(user_id, job_id, options);
    end

    def partner_params=(partner_params)
      if partner_params == nil
        raise ArgumentError.new('Please ensure that you send through partner params')
      end

      if !partner_params.is_a?(Hash)
        raise ArgumentError.new('Partner params needs to be a hash')
      end

      [:user_id, :job_id, :job_type].each do |key|
        unless partner_params[key] && !partner_params[key].nil? && !(partner_params[key].empty? if partner_params[key].is_a?(String))
          raise ArgumentError.new("Please make sure that #{key.to_s} is included in the partner params")
        end
      end

      @partner_params = partner_params
    end

    def images=(images)
      if images == nil
        raise ArgumentError.new('Please ensure that you send through image details')
      end

      if !images.is_a?(Array)
        raise ArgumentError.new('Image details needs to be an array')
      end

      # all job types require atleast a selfie
      if images.length == 0 || images.none? {|h| h[:image_type_id] == 0 || h[:image_type_id] == 2 }
        raise ArgumentError.new('You need to send through at least one selfie image')
      end

      @images = images.map { |image| symbolize_keys image }

    end

    def id_info=(id_info)

      updated_id_info = id_info

      if updated_id_info.nil?
        updated_id_info = {}
      end

      # if it doesnt exist, set it false
      if(!updated_id_info.key?(:entered) || id_info[:entered].empty?)
        updated_id_info[:entered] = "false"
      end

      # if it's a boolean
      if(!!updated_id_info[:entered] == updated_id_info[:entered])
        updated_id_info[:entered] = id_info[:entered].to_s
      end

      if updated_id_info[:entered] && updated_id_info[:entered] == 'true'
        [:country, :id_type, :id_number].each do |key|
          unless id_info[key] && !id_info[key].nil? && !id_info[key].empty?
            raise ArgumentError.new("Please make sure that #{key.to_s} is included in the id_info")
          end
        end
      end

      @id_info = updated_id_info
    end

    def options=(options)
      updated_options = options

      if updated_options.nil?
        updated_options = {}
      end

      [:optional_callback, :return_job_status, :return_image_links, :return_history].map do |key|
        if key != :optional_callback
          updated_options[key] = check_boolean(key, options)
        else
          updated_options[key] = check_string(key, options)
        end
      end

      @options = updated_options
    end

    private

    def symbolize_keys params
      (params.is_a?(Hash)) ? Hash[params.map{ |k, v| [k.to_sym, v] }] : params
    end

    def validate_return_data
      if (!@callback_url || @callback_url.empty?) && !@options[:return_job_status]
        raise ArgumentError.new("Please choose to either get your response via the callback or job status query")
      end
    end

    def validate_enroll_with_id
      if(((@images.none? {|h| h[:image_type_id] == 1 || h[:image_type_id] == 3 }) && @id_info[:entered] != 'true'))
        raise ArgumentError.new("You are attempting to complete a job type 1 without providing an id card image or id info")
      end
    end

    def check_boolean(key, obj)
      if (!obj || !obj[key])
        return false
      end

      if !!obj[key] != obj[key]
        raise ArgumentError.new("#{key} needs to be a boolean")
      end

      return obj[key]
    end

    def check_string(key, obj)
      if (!obj || !obj[key])
        return ''
      else
        return obj[key]
      end
    end

    def determine_sec_key
      @sec_key = SmileIdentityCore::Signature.new(@partner_id, @api_key).generate_sec_key(@timestamp)[:sec_key]
    end

    def configure_prep_upload_json

      body = {
        file_name: 'selfie.zip',
        timestamp: @timestamp.to_s,
        signature: SmileIdentityCore::Signature.new(@partner_id, @api_key).generate_signature(@timestamp)[:signature],
        smile_client_id: @partner_id,
        partner_params: @partner_params,
        model_parameters: {}, # what is this for
        callback_url: @callback_url
      }
      p @timestamp
      JSON.generate(body)
    end

    def setup_requests

      url = "#{@url}/upload"
      request = Typhoeus::Request.new(
        url,
        method: 'POST',
        headers: {'Content-Type'=> "application/json"},
        body: configure_prep_upload_json
      )

      request.on_complete do |response|
        if response.success?

          prep_upload_response = JSON.parse(response.body)
          info_json = configure_info_json(prep_upload_response)

          file_upload_response = upload_file(prep_upload_response['upload_url'], info_json, prep_upload_response['smile_job_id'])
          return file_upload_response

        elsif response.timed_out?
          raise "#{response.code.to_s}: #{response.body}"
        elsif response.code == 0
          # Could not get an http response, something's wrong.
          raise "#{response.code.to_s}: #{response.body}"
        else
          # Received a non-successful http response.
          raise "#{response.code.to_s}: #{response.body}"
        end
      end
      request.run
    end

    def configure_info_json(server_information)
      info = {
        "package_information": {
          "apiVersion": {
            "buildNumber": 0,
            "majorVersion": 2,
            "minorVersion": 0
          },
          "language": "ruby"
        },
        "misc_information": {
          "sec_key": @sec_key,
          "retry": "false",
          "partner_params": @partner_params,
          "timestamp": @timestamp,
          "file_name": "selfie.zip", # figure out what to do here
          "smile_client_id": @partner_id,
          "callback_url": @callback_url,
          "userData": { # TO ASK what goes here
            "isVerifiedProcess": false,
            "name": "",
            "fbUserID": "",
            "firstName": "Bill",
            "lastName": "",
            "gender": "",
            "email": "",
            "phone": "",
            "countryCode": "+",
            "countryName": ""
          }
        },
        "id_info": @id_info,
        "images": configure_image_payload,
        "server_information": server_information
      }
      return info
    end

    def configure_image_payload
      @images.map { |i|
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
      }
    end

    def image_file?(type)
      type.to_i == 0 || type.to_i == 1
    end

    def zip_up_file(info_json)
      # https://info.michael-simons.eu/2008/01/21/using-rubyzip-to-create-zip-files-on-the-fly/
      Zip::OutputStream.write_buffer do |zos|
        zos.put_next_entry('info.json')
        zos.puts JSON.pretty_generate(info_json)

        if @images.length > 0
          @images.each do |img|
            if img[:image_type_id] == 0 || img[:image_type_id] == 1
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
        headers: {'Content-Type'=> "application/zip"},
        body: file.read,
      )

      request.on_complete do |response|
        if response.success?
          if @options[:return_job_status]
            @utilies_connection = SmileIdentityCore::Utilities.new(@partner_id, @api_key, @sid_server)
            job_response = query_job_status
            job_response["success"] = true
            job_response["smile_job_id"] = smile_job_id
            return job_response
          else
            return {success: true, smile_job_id: smile_job_id}.to_json
          end
        elsif response.timed_out?
          raise " #{response.code.to_s}: #{response.body}"
        elsif response.code == 0
          # Could not get an http response, something's wrong.
          raise " #{response.code.to_s}: #{response.body}"
        else
          # Received a non-successful http response.
          raise " #{response.code.to_s}: #{response.body}"
        end
      end
      request.run

    end

    def query_job_status(counter=0)
      counter < 4 ? (sleep 2) : (sleep 6)
      counter += 1

      response = @utilies_connection.get_job_status(@partner_params[:user_id], @partner_params[:job_id], @options)

      if response && (response['job_complete'] == true || counter == 20)
        return response
      else
        return query_job_status(counter)
      end

    end
  end
end
