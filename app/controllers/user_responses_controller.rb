class UserResponsesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_guest_can_submit, only: :create

  def create # rubocop:disable Metrics/MethodLength
    # rescue内でparams再取得を防ぐため、事前に変数に格納
    test_id = sanitized_test_id
    choice_ids = sanitized_choice_ids

    ActiveRecord::Base.transaction do
      Examination.create_result!(user_id: current_user.id,
                                 test_id:,
                                 attempt_date: DateTime.current,
                                 choice_ids:)
      redirect_to dashboard_path, notice: '試験結果を保存しました'
    rescue StandardError => e
      logger.error("試験結果の保存エラー: #{e.message}")
      @user_responses = choice_ids
      redirect_to test_path(test_id), alert: '試験結果を保存できませんでした'
    end
  end

  private

  def user_response_params
    params.require(:user_response).permit(:test_id, choice_ids: [])
  end

  def sanitized_test_id
    user_response_params[:test_id].to_i
  end

  def sanitized_choice_ids
    return [] if user_response_params[:choice_ids].blank?

    user_response_params[:choice_ids]
      .select { |id| id.to_s =~ /\A\d+\z/ }
      .map(&:to_i)
  end

  def ensure_guest_can_submit
    return unless current_user.guest? && current_user.guest_examination_limit_reached?

    redirect_to dashboard_path,
                alert: 'ゲストユーザーの受験回数が上限に達しました。受験結果を保持したい場合はアカウントを作成してください。'
  end
end
