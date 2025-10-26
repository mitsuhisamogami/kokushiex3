class ExaminationsController < ApplicationController
  before_action :authenticate_user!

  def show
    @examination = current_user.examinations.find(params[:id])
    authorize @examination
    @score = @examination.score
    @test = @examination.test
    # 参考：https://zenn.dev/mithuami/articles/c4b0e9694182d1#preload%E3%82%92%E6%8E%A8%E5%A5%A8%E3%81%99%E3%82%8B%E3%82%B1%E3%83%BC%E3%82%B9
    @questions = @test.test_sessions.preload(questions: :choices).map(&:questions).flatten
  end
end
