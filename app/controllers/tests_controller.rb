class TestsController < ApplicationController
  def show
    @test = Test.find(params[:id]).decorate
    # Test に紐づく Question を起点に必要な関連をまとめて読み込む
    @questions = Question.joins(test_session: :test)
                         .where(test_sessions: { test_id: @test.id })
                         .includes(:choices, :tags, test_session: :test)
                         .decorate
    # 解答を保持するためにuser_responseを持たせたいが、初回にエラーが出ないように空配列を渡す
    @user_responses = []
  end
end
