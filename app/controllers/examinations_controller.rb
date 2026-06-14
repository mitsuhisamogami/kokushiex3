class ExaminationsController < ApplicationController
  before_action :authenticate_user!

  def show
    @examination = current_user.examinations.includes(user_responses: :choice).find(params[:id])
    authorize @examination
    @score = @examination.score
    @test = @examination.test
    @questions = Question.includes(:choices, :tags, :test_session)
                         .joins(:test_session)
                         .where(test_sessions: { test_id: @test.id })
                         .order(:question_number)
    @tag_score_summary = Examinations::TagScoreSummary.new(@examination, questions: @questions).call
  end
end
