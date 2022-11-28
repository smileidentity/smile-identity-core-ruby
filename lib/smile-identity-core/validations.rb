# frozen_string_literal: true

module SmileIdentityCore
  module Validations   # :nodoc:
    def validate_partner_params(partner_params)
      raise ArgumentError, 'Please ensure that you send through partner params' if partner_params.nil?

      raise ArgumentError, 'Partner params needs to be a hash' unless partner_params.is_a?(Hash)

      %i[user_id job_id job_type].each do |key|
        if partner_params[key].to_s.empty?
          raise ArgumentError,
                "Please make sure that #{key} is included in the partner params"
        end
      end

      partner_params
    end

    def validate_id_info(id_info, required_id_info_fields)
      raise ArgumentError, 'Please make sure that id_info is not empty or nil' if id_info.nil? || id_info.empty?

      raise ArgumentError, 'Id info needs to be a hash' unless id_info.is_a?(Hash)

      required_id_info_fields.each do |key|
        raise ArgumentError, "Please make sure that #{key} is included in the id_info" if id_info[key].to_s.empty?
      end

      id_info
    end
  end
end
