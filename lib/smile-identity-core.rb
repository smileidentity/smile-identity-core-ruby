# frozen_string_literal: true

require_relative 'smile-identity-core/version'
require_relative 'smile-identity-core/web_api'
require_relative 'smile-identity-core/id_api'
require_relative 'smile-identity-core/aml_check'
require_relative 'smile-identity-core/signature'
require_relative 'smile-identity-core/utilities'
require_relative 'smile-identity-core/business_verification'
require_relative 'smile-identity-core/address_verification'
require_relative 'smile-identity-core/constants/env'
require_relative 'smile-identity-core/constants/image_type'
require_relative 'smile-identity-core/constants/job_type'

module SmileIdentityCore
  class Error < StandardError; end

  # Raised when the job status endpoint answers HTTP 429. retry_after holds the
  # Retry-After header in whole seconds, or nil when it is missing or a date.
  class RateLimitedError < Error
    attr_reader :retry_after

    def initialize(message, retry_after = nil)
      super(message)
      @retry_after = retry_after
    end
  end
end
