# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  def destroy
    guest_to_cleanup = guest_user_pending_cleanup
    super
    cleanup_guest_user(guest_to_cleanup)
  end

  def guest_sign_in
    user = User.create_guest
    sign_in user
    redirect_to tests_select_path, notice: 'ゲストユーザーとしてログインしました。'
  end

  def guest_sign_out
    guest_to_cleanup = current_user if current_user&.guest?
    destroy
    cleanup_guest_user(guest_to_cleanup, force: true)
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  def after_sign_in_path_for(_resource)
    dashboard_path
  end

  def after_sign_out_path_for(_resource)
    root_path
  end

  private

  def guest_user_pending_cleanup
    return unless current_user&.guest?

    current_user if current_user.guest_limit_reached?
  end

  def cleanup_guest_user(user, force: false)
    return unless user&.guest?
    return unless force || user.guest_limit_reached?

    user.destroy
  end
end
