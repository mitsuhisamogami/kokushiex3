# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  User.omniauth_providers.each do |provider|
    define_method(provider) do
      handle_callback
    end
  end

  def failure
    redirect_to failure_redirect_path, alert: t('oauth.identity_authenticator.failure')
  end

  private

  def handle_callback
    result = Oauth::IdentityAuthenticator.new(
      auth: request.env['omniauth.auth'],
      current_user:
    ).call

    if result.success?
      sign_in(:user, result.user)
      redirect_to after_sign_in_path_for(result.user), notice: result.message
    else
      redirect_to failure_redirect_path, alert: result.message
    end
  end

  def failure_redirect_path
    user_signed_in? ? account_path : new_user_session_path
  end
end
