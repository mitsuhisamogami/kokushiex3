module Oauth
  class AuthHashReader
    def initialize(auth)
      @auth = auth
    end

    def provider
      auth_value(:provider).to_s
    end

    def uid
      auth_value(:uid).to_s
    end

    def email
      @email ||= (info_value(:email).presence || raw_info_value(:email).presence).to_s.strip.downcase.presence
    end

    def name
      @name ||= info_value(:name).presence || raw_info_value(:name).presence
    end

    def image_url
      @image_url ||= info_value(:image).presence || info_value(:image_url).presence || raw_info_value(:picture).presence
    end

    def verified_email?
      return google_verified_email? if provider == 'google_oauth2'
      return line_verified_email? if provider == 'line'
      return true if truthy?(info_value(:email_verified))
      return false unless raw_info_email_matches?

      [
        raw_info_value(:email_verified),
        raw_info_value(:verified_email)
      ].any? { |value| truthy?(value) }
    end

    private

    attr_reader :auth

    def auth_value(key)
      fetch_value(auth, key)
    end

    def info_value(key)
      fetch_value(auth_value(:info), key)
    end

    def raw_info_value(key)
      fetch_value(profile_info, key)
    end

    def profile_info
      extra = auth_value(:extra)
      raw_info = fetch_value(extra, :raw_info)
      return raw_info unless provider == 'line' && raw_info.blank?

      fetch_value(extra, :id_info)
    end

    def id_info_value(key)
      fetch_value(fetch_value(auth_value(:extra), :id_info), key)
    end

    def raw_info_email_matches?
      raw_info_value(:email).to_s.strip.downcase.presence == email
    end

    def id_info_email_matches?
      id_info_value(:email).to_s.strip.downcase.presence == email
    end

    def google_verified_email?
      raw_info_email_matches? && raw_info_value(:email_verified) == true
    end

    def line_verified_email?
      # omniauth-line-v2 verifies the ID token via LINE /oauth2/v2.1/verify
      # and exposes that verified response as extra.id_info.
      return true if id_info_email_matches?
      return false unless raw_info_email_matches?

      [
        raw_info_value(:email_verified),
        raw_info_value(:verified_email)
      ].any?(true)
    end

    def fetch_value(object, key)
      return if object.blank?
      return object[key] if object.respond_to?(:key?) && object.key?(key)
      return object[key.to_s] if object.respond_to?(:key?) && object.key?(key.to_s)

      object.respond_to?(key) ? object.public_send(key) : object[key]
    end

    def truthy?(value)
      value == true || value.to_s == 'true'
    end
  end
end
