class ExaminationsController < ApplicationController
  before_action :authenticate_user!

  def show
    @examination = current_user.examinations.includes(user_responses: :choice).find(params[:id])
    authorize @examination
    @score = @examination.score
    @test = @examination.test
    @questions = Question.includes(:choices, :test_session)
                         .joins(:test_session)
                         .where(test_sessions: { test_id: @test.id })
                         .order(:question_number)
  end
end
