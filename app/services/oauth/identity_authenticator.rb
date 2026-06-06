module Oauth
  class IdentityAuthenticator
    Result = Data.define(:status, :user, :identity, :message) do
      def success?
        status == :success
      end
    end
    delegate :provider, :uid, :email, :name, :image_url, :verified_email?, to: :auth_reader

    def initialize(auth:, current_user:)
      @auth_reader = AuthHashReader.new(auth)
      @current_user = current_user
    end

    def call
      return failure(:invalid_auth) if provider.blank? || uid.blank?

      identity = UserIdentity.find_by(provider:, uid:)
      return authenticate_existing_identity(identity) if identity

      authenticate_new_identity
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      recover_from_persistence_error
    end

    private

    attr_reader :auth_reader, :current_user

    def authenticate_new_identity
      # ゲストのOAuth連携・本登録化は別フローで扱うため、この共通基盤では拒否する。
      return failure(:guest_user_not_allowed) if current_user&.guest?
      return connect_identity(current_user, :connected) if current_user

      authenticate_unregistered_user
    end

    def authenticate_unregistered_user
      return failure(:unverified_email) unless email.present? && verified_email?

      user = find_user_by_email
      return failure(:ambiguous_email) if user == :ambiguous
      return authenticate_verified_email_user(user) if user

      create_user_with_identity
    end

    def authenticate_verified_email_user(user)
      return failure(:guest_user_not_allowed) if user.guest?

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

    def create_user_with_identity
      user, identity = UserCreator.new(provider:, uid:, email:, name:, image_url:).call

      success(user, identity, :signed_up)
    end

    def find_user_by_email
      users = User.where('LOWER(email) = ?', email).limit(2).to_a
      return :ambiguous if users.many?

      users.first
    end

    def recover_from_persistence_error
      identity = UserIdentity.find_by(provider:, uid:)
      return authenticate_existing_identity(identity) if identity

      return failure(:already_connected_provider) if current_user
      return failure(:signup_failed) unless email.present? && verified_email?

      user = find_user_by_email
      return failure(:ambiguous_email) if user == :ambiguous
      return connect_identity_with_recovery(user, :signed_in) if user

      failure(:signup_failed)
    end

    def connect_identity_with_recovery(user, message_key)
      return failure(:guest_user_not_allowed) if user.guest?

      connect_identity(user, message_key)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      identity = UserIdentity.find_by(provider:, uid:)
      return authenticate_existing_identity(identity) if identity

      failure(:signup_failed)
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
