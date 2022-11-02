# frozen_string_literal: true

require 'smile-identity-core/version'
require 'smile-identity-core/web_api'
require 'smile-identity-core/id_api'
require 'smile-identity-core/signature'
require 'smile-identity-core/utilities'
require 'smile-identity-core/constants/image_type'
require 'smile-identity-core/constants/job_type'
require 'smile-identity-core/constants/env'

module SmileIdentityCore
  class Error < StandardError; end
end
