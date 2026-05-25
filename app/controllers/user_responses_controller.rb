class UserResponsesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_guest_can_submit, only: :create

  def create # rubocop:disable Metrics/MethodLength
    test_id = nil
    choice_ids = []

    begin
      # rescue内でparams再取得を防ぐため、事前に変数に格納
      test_id = sanitized_test_id
      choice_ids = sanitized_choice_ids

      # 途中失敗時にExaminationだけが残らないよう、rescueはtransactionの外で行う
      examination = ActiveRecord::Base.transaction do
        Examination.create_result!(user_id: current_user.id,
                                   test_id:,
                                   attempt_date: DateTime.current,
                                   choice_ids:)
      end
      redirect_to examination_path(examination), notice: '試験結果を保存しました'
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
    # 未回答で終了した場合は空配列として扱い、0回答のまま採点する
    return [] if user_response_params[:choice_ids].blank?

    # choice_idsが送信されている場合、不正値を空回答に変換せず改ざんとして失敗させる
    raise Examination::InvalidChoiceError, 'Invalid choice IDs provided' unless numeric_choice_ids?

    user_response_params[:choice_ids].map(&:to_i)
  end

  def numeric_choice_ids?
    user_response_params[:choice_ids].all? { |id| id.to_s =~ /\A\d+\z/ }
  end

  def ensure_guest_can_submit
    return unless current_user.guest? && current_user.guest_examination_limit_reached?

    redirect_to dashboard_path,
                alert: 'ゲストユーザーの受験回数が上限に達しました。受験結果を保持したい場合はアカウントを作成してください。'
  end
end
