module Oauth
  class UserCreator
    USERNAME_MAX_LENGTH = 50
    USERNAME_SUFFIX_SEARCH_LIMIT = 1_000

    def initialize(provider:, uid:, email:, name:, image_url:)
      @provider = provider
      @uid = uid
      @email = email
      @name = name
      @image_url = image_url
    end

    def call
      username = generated_username

      User.transaction do
        user = User.create!(
          email:,
          username:,
          password: SecureRandom.urlsafe_base64(32)
        )
        identity = user.user_identities.create!(identity_attributes)

        [user, identity]
      end
    end

    private

    attr_reader :provider, :uid, :email, :name, :image_url

    def identity_attributes
      {
        provider:,
        uid:,
        email:,
        name:,
        image_url:
      }
    end

    def generated_username
      base = truncate_username(name.presence || "#{provider_display_name}ユーザー")
      return base unless User.exists?(username: base)

      candidates = suffixed_username_candidates(base)
      taken_usernames = User.where(username: candidates).pluck(:username)
      candidates.find { |candidate| taken_usernames.exclude?(candidate) } || fallback_username(base)
    end

    def suffixed_username_candidates(base)
      (2..USERNAME_SUFFIX_SEARCH_LIMIT).map do |suffix_number|
        suffixed_username(base, suffix_number)
      end
    end

    def suffixed_username(base, suffix_number)
      suffix = "_#{suffix_number}"
      "#{base.first(USERNAME_MAX_LENGTH - suffix.length)}#{suffix}"
    end

    def fallback_username(base)
      suffix = "_#{SecureRandom.hex(4)}"
      "#{base.first(USERNAME_MAX_LENGTH - suffix.length)}#{suffix}"
    end

    def truncate_username(value)
      value.to_s.first(USERNAME_MAX_LENGTH)
    end

    def provider_display_name
      OmniAuth::Utils.camelize(provider)
    end
  end
end
