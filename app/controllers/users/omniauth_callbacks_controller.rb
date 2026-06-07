# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  %i[developer google_oauth2].each do |provider|
    define_method(provider) do
      handle_callback
    end
  end

  def failure
    redirect_to failure_redirect_path, alert: t('oauth.identity_authenticator.failure')
  end

  private

  def handle_callback
    return redirect_oauth_failure unless callback_provider_matches?

    redirect_oauth_result(authenticate_oauth_identity)
  end

  def redirect_oauth_result(result)
    if result.success?
      sign_in(:user, result.user)
      redirect_to after_sign_in_path_for(result.user), notice: result.message
    else
      redirect_to failure_redirect_path, alert: result.message
    end
  end

  def redirect_oauth_failure
    redirect_to failure_redirect_path, alert: t('oauth.identity_authenticator.failure')
  end

  def failure_redirect_path
    user_signed_in? ? account_path : new_user_session_path
  end

  def callback_provider_matches?
    auth_provider = request.env['omniauth.auth']&.provider.to_s
    callback_provider = params[:action].to_s

    auth_provider.present? && auth_provider == callback_provider
  end

  def authenticate_oauth_identity
    Oauth::IdentityAuthenticator.new(
      auth: request.env['omniauth.auth'],
      current_user:
    ).call
  end
end
