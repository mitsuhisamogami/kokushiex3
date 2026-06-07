# frozen_string_literal: true

module Oauth
  class ProviderConfig
    GOOGLE_PROVIDER = :google_oauth2
    GOOGLE_CLIENT_ID_ENV = 'GOOGLE_CLIENT_ID'
    GOOGLE_CLIENT_SECRET_ENV = 'GOOGLE_CLIENT_SECRET'

    class << self
      def google_client_id
        memoized(:@google_client_id) { configured_value(:client_id, GOOGLE_CLIENT_ID_ENV) }
      end

      def google_client_secret
        memoized(:@google_client_secret) { configured_value(:client_secret, GOOGLE_CLIENT_SECRET_ENV) }
      end

      def google_enabled?
        google_client_id.present? && google_client_secret.present?
      end

      def enabled_providers
        google_enabled? ? [GOOGLE_PROVIDER] : []
      end

      def reset!
        remove_instance_variable(:@google_client_id) if instance_variable_defined?(:@google_client_id)
        remove_instance_variable(:@google_client_secret) if instance_variable_defined?(:@google_client_secret)
      end

      private

      def memoized(variable_name)
        return instance_variable_get(variable_name) if instance_variable_defined?(variable_name)

        instance_variable_set(variable_name, yield)
      end

      def configured_value(credentials_key, env_key)
        credentials_value = Rails.application.credentials.dig(:google_oauth, credentials_key)
        credentials_value.to_s.presence || ENV[env_key].to_s.presence
      end
    end
  end
end
