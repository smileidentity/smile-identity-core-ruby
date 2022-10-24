# frozen_string_literal: true

RSpec.describe SmileIdentityCore do
  describe 'sets server url' do
    it 'returns the test url' do
      expect(SmileIdentityCore::SID_SERVER_MAPPING[SmileIdentityCore::TEST]).to eq('https://testapi.smileidentity.com/v1')
    end

    it 'returns the live url' do
      expect(SmileIdentityCore::SID_SERVER_MAPPING[SmileIdentityCore::LIVE]).to eq('https://api.smileidentity.com/v1')
    end
  end
end
