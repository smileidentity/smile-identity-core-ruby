RSpec.describe SmileIdentityCore::Configuration do

  describe 'configuration' do
    let(:partner_id) { '002' }
    let(:api_key) { 'xxx' }
    let(:default_callback) { 'http://localhost' }
    let(:sid_server) { 'http://sid-server' }

    let(:configuration) do
      described_class.new do |config|
        config.partner_id = partner_id
        config.api_key = api_key
        config.default_callback = default_callback
        config.sid_server = sid_server
      end
    end

    context 'configuration' do
      it 'accepts a partner_id' do
        expect(configuration.partner_id).to eq(partner_id)
      end

      it 'accepts an api_key' do
        expect(configuration.api_key).to eq(api_key)
      end

      it 'accepts a default_callback' do
        expect(configuration.default_callback).to eq(default_callback)
      end

      it 'accepts a sid_server' do
        expect(configuration.sid_server).to eq(sid_server)
      end
    end
  end
end
