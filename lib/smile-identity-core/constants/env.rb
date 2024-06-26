# frozen_string_literal: true

module SmileIdentityCore
  # The ENV module contains constants and utility methods for mapping
  # managing aliases to Smile Identity servers.
  module ENV
    SID_SERVER_MAPPING = {
      '0' => 'https://testapi.smileidentity.com/v1',
      '1' => 'https://api.smileidentity.com/v1',
    }.freeze

    TEST = '0'
    LIVE = '1'

    module_function

    def determine_url(sid_server)
      if sid_server.to_s =~ URI::DEFAULT_PARSER.make_regexp
        sid_server
      else
        SID_SERVER_MAPPING[sid_server.to_s] || sid_server
      end
    end
  end
end
