class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  include Draper::Decoratable

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end

  # Devise認証失敗時のリダイレクト先をカスタマイズ
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end
end
