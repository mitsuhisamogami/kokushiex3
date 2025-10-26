class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # current_userの最新のexamaminationを取得
    @latest_examination = current_user.examinations.order(created_at: :desc).first
    # latest_examinationのscoreを取得
    @latest_score = @latest_examination.score if @latest_examination
  end
end
