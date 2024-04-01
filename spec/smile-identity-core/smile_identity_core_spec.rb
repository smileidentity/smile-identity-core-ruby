# frozen_string_literal: true

RSpec.describe SmileIdentityCore do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be_nil
  end

  describe 'sets server url' do
    it 'returns the test url' do
      expect(described_class::ENV::SID_SERVER_MAPPING[described_class::ENV::TEST]).to eq('https://testapi.smileidentity.com/v1')
    end

    it 'returns the live url' do
      expect(described_class::ENV::SID_SERVER_MAPPING[described_class::ENV::LIVE]).to eq('https://api.smileidentity.com/v1')
    end
  end
end
