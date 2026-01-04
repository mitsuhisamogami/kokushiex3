class TestsController < ApplicationController
  def show
    @test = Test.find(params[:id]).decorate
    @test_sessions = @test.test_sessions.includes(questions: :choices)
    # 各TestSessionに紐づくquestionsを全て取得する
    @questions = @test_sessions.flat_map { |session| session.questions.decorate }
    # 解答を保持するためにuser_responseを持たせたいが、初回にエラーが出ないように空配列を渡す
    @user_responses = []
  end
end
