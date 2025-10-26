class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  include Draper::Decoratable
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end

  # Devise認証失敗時のリダイレクト先をカスタマイズ
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end

  private

  def user_not_authorized
    flash[:alert] = 'この操作を実行する権限がありません。'
    redirect_to(request.referer || root_path)
  end

  def record_not_found
    flash[:alert] = '指定されたデータが見つかりませんでした。'
    redirect_to(request.referer || root_path)
  end
end
