# frozen_string_literal: true

module OauthTestHelpers
  GOOGLE_CLIENT_ID = 'google-client-id'
  GOOGLE_CLIENT_SECRET = 'google-client-secret'

  def with_google_oauth_routes(enabled: true)
    original_enabled_providers = Oauth::ProviderConfig.singleton_class.instance_method(:enabled_providers)
    replace_enabled_providers(enabled ? [:google_oauth2] : [])
    Rails.application.reload_routes!

    yield
  ensure
    restore_enabled_providers(original_enabled_providers)
    Rails.application.reload_routes!
  end

  def with_google_oauth_credentials(client_id: GOOGLE_CLIENT_ID, client_secret: GOOGLE_CLIENT_SECRET,
                                    env_client_id: nil, env_client_secret: nil)
    original_env = google_oauth_env
    set_google_oauth_env(client_id: env_client_id, client_secret: env_client_secret)
    Oauth::ProviderConfig.reset!

    stub_google_oauth_credentials(client_id:, client_secret:)

    yield
  ensure
    set_google_oauth_env(**original_env)
    Oauth::ProviderConfig.reset!
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

  def google_oauth_env
    {
      client_id: ENV.fetch('GOOGLE_CLIENT_ID', nil),
      client_secret: ENV.fetch('GOOGLE_CLIENT_SECRET', nil)
    }
  end

  def set_google_oauth_env(client_id:, client_secret:)
    set_env('GOOGLE_CLIENT_ID', client_id)
    set_env('GOOGLE_CLIENT_SECRET', client_secret)
  end

  def stub_google_oauth_credentials(client_id:, client_secret:)
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(:google_oauth, :client_id).and_return(client_id)
    allow(Rails.application.credentials).to receive(:dig).with(:google_oauth, :client_secret).and_return(client_secret)
  end

  def set_env(key, value)
    value.nil? ? ENV.delete(key) : ENV[key] = value
  end
end

RSpec.configure do |config|
  config.include OauthTestHelpers
end
