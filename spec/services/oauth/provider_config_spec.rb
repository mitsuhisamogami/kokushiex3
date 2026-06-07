# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Oauth::ProviderConfig do
  around do |example|
    original_client_id = ENV.fetch('GOOGLE_CLIENT_ID', nil)
    original_client_secret = ENV.fetch('GOOGLE_CLIENT_SECRET', nil)
    ENV.delete('GOOGLE_CLIENT_ID')
    ENV.delete('GOOGLE_CLIENT_SECRET')
    described_class.reset!

    example.run
  ensure
    original_client_id.nil? ? ENV.delete('GOOGLE_CLIENT_ID') : ENV['GOOGLE_CLIENT_ID'] = original_client_id
    if original_client_secret.nil?
      ENV.delete('GOOGLE_CLIENT_SECRET')
    else
      ENV['GOOGLE_CLIENT_SECRET'] = original_client_secret
    end
    described_class.reset!
  end

  def stub_google_credentials(client_id:, client_secret:)
    described_class.reset!
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(:google_oauth, :client_id).and_return(client_id)
    allow(Rails.application.credentials).to receive(:dig).with(:google_oauth, :client_secret).and_return(client_secret)
  end

  describe '.google_enabled?' do
    it 'client idとsecretが両方ある場合にtrueを返す' do
      stub_google_credentials(client_id: 'credential-id', client_secret: 'credential-secret')

      expect(described_class).to be_google_enabled
      expect(described_class.enabled_providers).to eq [:google_oauth2]
    end

    it 'client idのみの場合にfalseを返す' do
      stub_google_credentials(client_id: 'credential-id', client_secret: nil)

      expect(described_class).not_to be_google_enabled
      expect(described_class.enabled_providers).to be_empty
    end

    it 'client secretのみの場合にfalseを返す' do
      stub_google_credentials(client_id: nil, client_secret: 'credential-secret')

      expect(described_class).not_to be_google_enabled
      expect(described_class.enabled_providers).to be_empty
    end

    it 'blankは未設定として扱う' do
      stub_google_credentials(client_id: ' ', client_secret: '')

      expect(described_class).not_to be_google_enabled
      expect(described_class.enabled_providers).to be_empty
    end

    it 'credentialsをENVより優先する' do
      stub_google_credentials(client_id: 'credential-id', client_secret: 'credential-secret')
      ENV['GOOGLE_CLIENT_ID'] = 'env-id'
      ENV['GOOGLE_CLIENT_SECRET'] = 'env-secret'

      expect(described_class.google_client_id).to eq 'credential-id'
      expect(described_class.google_client_secret).to eq 'credential-secret'
    end

    it 'credentialsがblankの場合はENVへfallbackする' do
      stub_google_credentials(client_id: ' ', client_secret: nil)
      ENV['GOOGLE_CLIENT_ID'] = 'env-id'
      ENV['GOOGLE_CLIENT_SECRET'] = 'env-secret'

      expect(described_class).to be_google_enabled
      expect(described_class.google_client_id).to eq 'env-id'
      expect(described_class.google_client_secret).to eq 'env-secret'
    end
  end
end
