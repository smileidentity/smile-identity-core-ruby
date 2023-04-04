# frozen_string_literal: true

require_relative 'smile-identity-core/version'
require_relative 'smile-identity-core/web_api'
require_relative 'smile-identity-core/id_api'
require_relative 'smile-identity-core/aml_check'
require_relative 'smile-identity-core/signature'
require_relative 'smile-identity-core/utilities'
require_relative 'smile-identity-core/business_verification'
require_relative 'smile-identity-core/constants/env'
require_relative 'smile-identity-core/constants/image_type'
require_relative 'smile-identity-core/constants/job_type'

module SmileIdentityCore
  class Error < StandardError; end
end
