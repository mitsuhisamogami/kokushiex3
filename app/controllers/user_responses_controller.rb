class UserResponsesController < ApplicationController
  before_action :authenticate_user!

  def create # rubocop:disable Metrics/MethodLength
    ActiveRecord::Base.transaction do
      Examination.create_result!(user_id: current_user.id,
                                 test_id: params[:test_id],
                                 attempt_date: DateTime.current,
                                 choice_ids: params[:user_response][:choice_ids])
      redirect_to dashboard_path, notice: '試験結果を保存しました'
    rescue StandardError => e
      logger.error("試験結果の保存エラー: #{e.message}")
      @user_responses = params[:user_response][:choice_ids]
      redirect_to test_path(params[:test_id]), alert: '試験結果を保存できませんでした'
    end
  end
end
