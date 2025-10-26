class ScoresController < ApplicationController
  before_action :authenticate_user!

  def show
    @examination = Examination.find(params[:examination_id])
    @score = @examination.score
    authorize @score

    return unless @score.nil?

    redirect_to examination_path(@examination), alert: 'スコアが存在しません。'
  end
end
