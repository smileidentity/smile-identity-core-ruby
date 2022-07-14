# frozen_string_literal: true

module SmileIdentityCore
  module Configuration
    SID_SERVER_MAPPING = {
      '0' => 'https://testapi.smileidentity.com/v1',
      '1' => 'https://api.smileidentity.com/v1'
    }.freeze

    TEST = '0'
    LIVE = '1'
  end
end
