# frozen_string_literal: true

module Oauth
  class ProviderConfig
    PROVIDERS = {
      google_oauth2: {
        credentials_key: :google_oauth,
        env_client_id: 'GOOGLE_CLIENT_ID',
        env_client_secret: 'GOOGLE_CLIENT_SECRET'
      },
      line: {
        credentials_key: :line_oauth,
        env_client_id: 'LINE_CLIENT_ID',
        env_client_secret: 'LINE_CLIENT_SECRET'
      }
    }.freeze

    class << self
      def google_client_id
        client_id_for(:google_oauth2)
      end

      def google_client_secret
        client_secret_for(:google_oauth2)
      end

      def google_enabled?
        enabled?(:google_oauth2)
      end

      def line_client_id
        client_id_for(:line)
      end

      def line_client_secret
        client_secret_for(:line)
      end

      def line_enabled?
        enabled?(:line)
      end

      def enabled_providers
        memoized(:@enabled_providers) do
          PROVIDERS.keys.filter { |provider| enabled?(provider) }
        end
      end

      def reset!
        PROVIDERS.each_key do |provider|
          remove_memoized(:"@#{provider}_client_id")
          remove_memoized(:"@#{provider}_client_secret")
        end
        remove_memoized(:@enabled_providers)
      end

      private

      def enabled?(provider)
        client_id_for(provider).present? && client_secret_for(provider).present?
      end

      def client_id_for(provider)
        memoized(:"@#{provider}_client_id") { configured_value(provider, :client_id) }
      end

      def client_secret_for(provider)
        memoized(:"@#{provider}_client_secret") { configured_value(provider, :client_secret) }
      end

      def memoized(variable_name)
        return instance_variable_get(variable_name) if instance_variable_defined?(variable_name)

        instance_variable_set(variable_name, yield)
      end

      def remove_memoized(variable_name)
        remove_instance_variable(variable_name) if instance_variable_defined?(variable_name)
      end

      def configured_value(provider, value_key)
        config = PROVIDERS.fetch(provider)
        env_key = config.fetch(:"env_#{value_key}")
        credentials_value = Rails.application.credentials.dig(config.fetch(:credentials_key), value_key)
        credentials_value.to_s.presence || ENV[env_key].to_s.presence
      end
    end
  end
end
