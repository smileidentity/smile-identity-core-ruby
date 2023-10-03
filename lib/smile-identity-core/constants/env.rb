# frozen_string_literal: true

module SmileIdentityCore
  module ENV
    SID_SERVER_MAPPING = {
      '0' => 'https://testapi.smileidentity.com/v1',
      '1' => 'https://api.smileidentity.com/v1'
    }.freeze

    TEST = '0'
    LIVE = '1'

    module_function

    def determine_url(sid_server)
      if sid_server.to_s !~ URI::DEFAULT_PARSER.make_regexp
        SID_SERVER_MAPPING[sid_server.to_s]
      else
        sid_server
      end
    end
  end
end
