# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SmileIdentityCore::ENV do
  describe '.determine_url' do
    context 'when sid_server is an environment key' do
      it 'returns the mapped URL for TEST' do
        expect(described_class.determine_url(described_class::TEST))
          .to eq('https://testapi.smileidentity.com/v1')
      end

      it 'returns the mapped URL for LIVE' do
        expect(described_class.determine_url(described_class::LIVE))
          .to eq('https://api.smileidentity.com/v1')
      end
    end

    context 'when sid_server is a valid URL' do
      let(:valid_url) { 'https://example.com/v1' }

      it 'returns the given URL' do
        expect(described_class.determine_url(valid_url)).to eq(valid_url)
      end
    end

    context 'when sid_server is neither a URL nor an environment key' do
      let(:invalid_key) { 'random_key' }

      it 'returns the input value' do
        expect(described_class.determine_url(invalid_key)).to eq(invalid_key)
      end
    end
  end
end
