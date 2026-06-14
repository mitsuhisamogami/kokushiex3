# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module OauthTestHelpers
  GOOGLE_CLIENT_ID = 'google-client-id'
  GOOGLE_CLIENT_SECRET = 'google-client-secret'
  LINE_CLIENT_ID = 'line-client-id'
  LINE_CLIENT_SECRET = 'line-client-secret'

  def with_google_oauth_routes(enabled: true, &)
    with_oauth_routes(providers: enabled ? [:google_oauth2] : [], &)
  end

  def with_oauth_routes(providers:)
    original_enabled_providers = Oauth::ProviderConfig.singleton_class.instance_method(:enabled_providers)
    replace_enabled_providers(providers)
    Rails.application.reload_routes!

    yield
  ensure
    restore_enabled_providers(original_enabled_providers)
    Rails.application.reload_routes!
  end

  def with_google_oauth_credentials(client_id: GOOGLE_CLIENT_ID, client_secret: GOOGLE_CLIENT_SECRET,
                                    env_client_id: nil, env_client_secret: nil, &)
    with_oauth_credentials(
      config: oauth_config(:google_oauth, 'GOOGLE_CLIENT_ID', 'GOOGLE_CLIENT_SECRET'),
      client_id:,
      client_secret:,
      env_client_id:,
      env_client_secret:,
      &
    )
  end

  def with_line_oauth_credentials(client_id: LINE_CLIENT_ID, client_secret: LINE_CLIENT_SECRET,
                                  env_client_id: nil, env_client_secret: nil, &)
    with_oauth_credentials(
      config: oauth_config(:line_oauth, 'LINE_CLIENT_ID', 'LINE_CLIENT_SECRET'),
      client_id:,
      client_secret:,
      env_client_id:,
      env_client_secret:,
      &
    )
  end

  def with_oauth_credentials(config:, client_id:, client_secret:, env_client_id:, env_client_secret:)
    original_env = oauth_env(config)
    set_oauth_env(config, client_id: env_client_id, client_secret: env_client_secret)
    Oauth::ProviderConfig.reset!

    stub_oauth_credentials(provider: config[:provider], client_id:, client_secret:)

    yield
  ensure
    set_oauth_env(config, **original_env)
    Oauth::ProviderConfig.reset!
  end

  def mock_line_auth_hash(**overrides)
    attributes = default_line_auth_attributes.merge(overrides)

    OmniAuth::AuthHash.new(
      provider: 'line',
      uid: attributes[:uid],
      info: line_auth_info(attributes),
      credentials: attributes[:credentials],
      extra: line_auth_extra(attributes)
    )
  end

  def with_restored_devise_omniauth_configs
    original_configs = Devise.omniauth_configs.dup

    yield
  ensure
    Devise.omniauth_configs.clear
    Devise.omniauth_configs.merge!(original_configs)
  end

  private

  def replace_enabled_providers(providers)
    Oauth::ProviderConfig.define_singleton_method(:enabled_providers) { providers }
  end

  def restore_enabled_providers(original_enabled_providers)
    Oauth::ProviderConfig.singleton_class.define_method(:enabled_providers, original_enabled_providers)
  end

  def oauth_config(provider, client_id_key, client_secret_key)
    {
      provider:,
      client_id_key:,
      client_secret_key:
    }
  end

  def oauth_env(config)
    {
      client_id: ENV.fetch(config[:client_id_key], nil),
      client_secret: ENV.fetch(config[:client_secret_key], nil)
    }
  end

  def set_oauth_env(config, client_id:, client_secret:)
    set_env(config[:client_id_key], client_id)
    set_env(config[:client_secret_key], client_secret)
  end

  def stub_oauth_credentials(provider:, client_id:, client_secret:)
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(provider, :client_id).and_return(client_id)
    allow(Rails.application.credentials).to receive(:dig).with(provider, :client_secret).and_return(client_secret)
  end

  def set_env(key, value)
    value.nil? ? ENV.delete(key) : ENV[key] = value
  end

  def default_line_auth_attributes
    {
      uid: 'line-uid-123',
      email: 'line-user@example.com',
      name: 'LINE User',
      image: 'https://example.com/line-avatar.png',
      raw_info: nil,
      id_info: nil,
      credentials: nil
    }
  end

  def line_id_info(attributes)
    return attributes[:id_info] if attributes[:id_info]
    return if attributes[:raw_info]

    {
      email: attributes[:email],
      name: attributes[:name],
      picture: attributes[:image]
    }
  end

  def line_auth_info(attributes)
    attributes.slice(:email, :name, :image)
  end

  def line_auth_extra(attributes)
    {}.tap do |extra|
      extra[:raw_info] = attributes[:raw_info] if attributes[:raw_info]
      extra[:id_info] = line_id_info(attributes) if line_id_info(attributes)
    end
  end
end
# rubocop:enable Metrics/ModuleLength

RSpec.configure do |config|
  config.include OauthTestHelpers
end
