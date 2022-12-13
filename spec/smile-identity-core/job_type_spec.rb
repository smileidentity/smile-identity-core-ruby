# frozen_string_literal: true

RSpec.describe SmileIdentityCore::JobType do
  describe 'checks job type' do
    it 'BIOMETRIC_KYC is numeric' do
      expect(described_class::BIOMETRIC_KYC).to eq(1)
    end

    it 'SMART_SELFIE_AUTHENTICATION is numeric' do
      expect(described_class::SMART_SELFIE_AUTHENTICATION).to eq(2)
    end

    it 'SMART_SELFIE_REGISTRATION is numeric' do
      expect(described_class::SMART_SELFIE_REGISTRATION).to eq(4)
    end

    it 'BASIC_KYC is numeric' do
      expect(described_class::BASIC_KYC).to eq(5)
    end

    it 'ENHANCED_KYC is numeric' do
      expect(described_class::ENHANCED_KYC).to eq(5)
    end

    it 'DOCUMENT_VERIFICATION is numeric' do
      expect(described_class::DOCUMENT_VERIFICATION).to eq(6)
    end

    it 'BUSINESS_VERIFICATION is numeric' do
      expect(described_class::BUSINESS_VERIFICATION).to eq(7)
    end

    it 'UPDATE_PHOTO is numeric' do
      expect(described_class::UPDATE_PHOTO).to eq(8)
    end

    it 'COMPARE_USER_INFO is numeric' do
      expect(described_class::COMPARE_USER_INFO).to eq(9)
    end
  end
end
