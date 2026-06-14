# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Oauth::ProviderConfig do
  around do |example|
    original_env = {
      'GOOGLE_CLIENT_ID' => ENV.fetch('GOOGLE_CLIENT_ID', nil),
      'GOOGLE_CLIENT_SECRET' => ENV.fetch('GOOGLE_CLIENT_SECRET', nil),
      'LINE_CLIENT_ID' => ENV.fetch('LINE_CLIENT_ID', nil),
      'LINE_CLIENT_SECRET' => ENV.fetch('LINE_CLIENT_SECRET', nil)
    }

    original_env.each_key { |key| ENV.delete(key) }
    described_class.reset!

    example.run
  ensure
    original_env.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
    described_class.reset!
  end

  def stub_oauth_credentials(google_client_id: nil, google_client_secret: nil, line_client_id: nil,
                             line_client_secret: nil)
    described_class.reset!
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    stub_google_credentials(client_id: google_client_id, client_secret: google_client_secret)
    stub_line_credentials(client_id: line_client_id, client_secret: line_client_secret)
  end

  def stub_google_credentials(client_id:, client_secret:)
    allow(Rails.application.credentials).to receive(:dig)
      .with(:google_oauth, :client_id).and_return(client_id)
    allow(Rails.application.credentials).to receive(:dig)
      .with(:google_oauth, :client_secret).and_return(client_secret)
  end

  def stub_line_credentials(client_id:, client_secret:)
    allow(Rails.application.credentials).to receive(:dig)
      .with(:line_oauth, :client_id).and_return(client_id)
    allow(Rails.application.credentials).to receive(:dig)
      .with(:line_oauth, :client_secret).and_return(client_secret)
  end

  describe '.google_enabled?' do
    it 'client idとsecretが両方ある場合にtrueを返す' do
      stub_oauth_credentials(google_client_id: 'credential-id', google_client_secret: 'credential-secret')

      expect(described_class).to be_google_enabled
      expect(described_class.enabled_providers).to eq [:google_oauth2]
    end

    it 'client idのみの場合にfalseを返す' do
      stub_oauth_credentials(google_client_id: 'credential-id', google_client_secret: nil)

      expect(described_class).not_to be_google_enabled
      expect(described_class.enabled_providers).to be_empty
    end

    it 'client secretのみの場合にfalseを返す' do
      stub_oauth_credentials(google_client_id: nil, google_client_secret: 'credential-secret')

      expect(described_class).not_to be_google_enabled
      expect(described_class.enabled_providers).to be_empty
    end

    it 'blankは未設定として扱う' do
      stub_oauth_credentials(google_client_id: ' ', google_client_secret: '')

      expect(described_class).not_to be_google_enabled
      expect(described_class.enabled_providers).to be_empty
    end

    it 'credentialsをENVより優先する' do
      stub_oauth_credentials(google_client_id: 'credential-id', google_client_secret: 'credential-secret')
      ENV['GOOGLE_CLIENT_ID'] = 'env-id'
      ENV['GOOGLE_CLIENT_SECRET'] = 'env-secret'

      expect(described_class.google_client_id).to eq 'credential-id'
      expect(described_class.google_client_secret).to eq 'credential-secret'
    end

    it 'credentialsがblankの場合はENVへfallbackする' do
      stub_oauth_credentials(google_client_id: ' ', google_client_secret: nil)
      ENV['GOOGLE_CLIENT_ID'] = 'env-id'
      ENV['GOOGLE_CLIENT_SECRET'] = 'env-secret'

      expect(described_class).to be_google_enabled
      expect(described_class.google_client_id).to eq 'env-id'
      expect(described_class.google_client_secret).to eq 'env-secret'
    end
  end

  describe '.line_enabled?' do
    it 'line_oauthのclient idとsecretが両方ある場合にtrueを返す' do
      stub_oauth_credentials(line_client_id: 'line-credential-id', line_client_secret: 'line-credential-secret')

      expect(described_class).to be_line_enabled
      expect(described_class.enabled_providers).to eq [:line]
    end

    it 'client idのみの場合にfalseを返す' do
      stub_oauth_credentials(line_client_id: 'line-credential-id', line_client_secret: nil)

      expect(described_class).not_to be_line_enabled
      expect(described_class.enabled_providers).to be_empty
    end

    it 'client secretのみの場合にfalseを返す' do
      stub_oauth_credentials(line_client_id: nil, line_client_secret: 'line-credential-secret')

      expect(described_class).not_to be_line_enabled
      expect(described_class.enabled_providers).to be_empty
    end

    it 'credentialsをENVより優先する' do
      stub_oauth_credentials(line_client_id: 'line-credential-id', line_client_secret: 'line-credential-secret')
      ENV['LINE_CLIENT_ID'] = 'line-env-id'
      ENV['LINE_CLIENT_SECRET'] = 'line-env-secret'

      expect(described_class.line_client_id).to eq 'line-credential-id'
      expect(described_class.line_client_secret).to eq 'line-credential-secret'
    end

    it 'credentialsがblankの場合はENVへfallbackする' do
      stub_oauth_credentials(line_client_id: '', line_client_secret: ' ')
      ENV['LINE_CLIENT_ID'] = 'line-env-id'
      ENV['LINE_CLIENT_SECRET'] = 'line-env-secret'

      expect(described_class).to be_line_enabled
      expect(described_class.line_client_id).to eq 'line-env-id'
      expect(described_class.line_client_secret).to eq 'line-env-secret'
    end
  end

  describe '.enabled_providers' do
    it 'Googleのみ有効な場合はgoogle_oauth2のみ返す' do
      stub_oauth_credentials(google_client_id: 'google-id', google_client_secret: 'google-secret')

      expect(described_class.enabled_providers).to eq [:google_oauth2]
    end

    it 'LINEのみ有効な場合はlineのみ返す' do
      stub_oauth_credentials(line_client_id: 'line-id', line_client_secret: 'line-secret')

      expect(described_class.enabled_providers).to eq [:line]
    end

    it 'GoogleとLINEが有効な場合はGoogleからLINEの順で返す' do
      stub_oauth_credentials(
        google_client_id: 'google-id',
        google_client_secret: 'google-secret',
        line_client_id: 'line-id',
        line_client_secret: 'line-secret'
      )

      expect(described_class.enabled_providers).to eq %i[google_oauth2 line]
    end

    it 'GoogleとLINEが無効な場合は空配列を返す' do
      stub_oauth_credentials

      expect(described_class.enabled_providers).to be_empty
    end

    it 'reset!後にenabled_providersのキャッシュを更新する' do
      stub_oauth_credentials(google_client_id: 'google-id', google_client_secret: 'google-secret')
      expect(described_class.enabled_providers).to eq [:google_oauth2]

      stub_oauth_credentials(line_client_id: 'line-id', line_client_secret: 'line-secret')
      described_class.reset!

      expect(described_class.enabled_providers).to eq [:line]
    end
  end
end
