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
      @email ||= info_value(:email).to_s.strip.downcase.presence
    end

    def name
      @name ||= info_value(:name).presence
    end

    def image_url
      @image_url ||= info_value(:image).presence || info_value(:image_url).presence
    end

    def verified_email?
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
      fetch_value(fetch_value(auth_value(:extra), :raw_info), key)
    end

    def raw_info_email_matches?
      raw_info_value(:email).to_s.strip.downcase.presence == email
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
