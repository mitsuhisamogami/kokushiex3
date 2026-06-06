module Oauth
  class IdentityAuthenticator
    Result = Data.define(:status, :user, :identity, :message) do
      def success?
        status == :success
      end
    end

    def initialize(auth:, current_user:)
      @auth = auth
      @current_user = current_user
    end

    def call
      return failure(:invalid_auth) if provider.blank? || uid.blank?

      identity = UserIdentity.find_by(provider:, uid:)
      return authenticate_existing_identity(identity) if identity

      authenticate_new_identity
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      failure(:already_connected_provider)
    end

    private

    attr_reader :auth, :current_user

    def authenticate_new_identity
      # ゲストのOAuth連携・本登録化は別フローで扱うため、この共通基盤では拒否する。
      return failure(:guest_user_not_allowed) if current_user&.guest?
      return connect_identity(current_user, :connected) if current_user

      user = find_verified_email_user
      return failure(:unverified_email) unless user

      connect_identity(user, :signed_in)
    end

    def authenticate_existing_identity(identity)
      # 過去データなどでゲストにidentityが紐づいていても、OAuthログインには使わない。
      return failure(:guest_user_not_allowed) if identity.user.guest?

      if current_user && identity.user != current_user
        failure(:connected_to_another_user)
      else
        success(identity.user, identity, current_user ? :already_connected : :signed_in)
      end
    end

    def connect_identity(user, message_key)
      # 個人情報を最小化するため、tokenやraw_infoは保存しない。
      identity = user.user_identities.create!(
        provider:,
        uid:,
        email:,
        name:,
        image_url:
      )
      success(user, identity, message_key)
    end

    def find_verified_email_user
      return unless email.present? && verified_email?

      user = User.find_by('LOWER(email) = ?', email.downcase)
      return if user&.guest?

      user
    end

    def provider
      auth_value(:provider).to_s
    end

    def uid
      auth_value(:uid).to_s
    end

    def email
      @email ||= info_value(:email).to_s.downcase.presence
    end

    def name
      @name ||= info_value(:name).presence
    end

    def image_url
      @image_url ||= info_value(:image).presence || info_value(:image_url).presence
    end

    def verified_email?
      # provider固有のverifiedはemail検証以外を指すことがあるため、email検証キーだけを見る。
      [
        info_value(:email_verified),
        raw_info_value(:email_verified),
        raw_info_value(:verified_email)
      ].any? { |value| truthy?(value) }
    end

    def auth_value(key)
      fetch_value(auth, key)
    end

    def info_value(key)
      fetch_value(auth_value(:info), key)
    end

    def raw_info_value(key)
      fetch_value(fetch_value(auth_value(:extra), :raw_info), key)
    end

    def fetch_value(object, key)
      return if object.blank?

      object.respond_to?(key) ? object.public_send(key) : object[key]
    end

    def truthy?(value)
      value == true || value.to_s == 'true'
    end

    def success(user, identity, message_key)
      Result.new(status: :success, user:, identity:, message: message(message_key))
    end

    def failure(message_key)
      Result.new(status: :failure, user: nil, identity: nil, message: message(message_key))
    end

    def message(key)
      I18n.t("oauth.identity_authenticator.#{key}")
    end
  end
end
