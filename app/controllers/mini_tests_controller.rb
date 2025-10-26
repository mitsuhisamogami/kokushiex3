class MiniTestsController < ApplicationController
  def index
    form = MiniTestSearchForm.new(params)
    if form.valid?
      @questions = form.search
      @user_responses = []
    else
      redirect_to tests_select_path, alert: form.errors.full_messages.join(', ')
    end
  end

  def create
    @selected_answers = Choice.mini_test_answers(sanitized_choice_ids)
    @questions = Question.where(id: sanitized_question_ids)

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def mini_test_params
    params.permit(user_response: { choice_ids: [] }, question_ids: [])
  end

  def sanitized_choice_ids
    return [] if mini_test_params.dig(:user_response, :choice_ids).blank?

    mini_test_params.dig(:user_response, :choice_ids)
                    .select { |id| id.to_s =~ /\A\d+\z/ }
                    .map(&:to_i)
  end

  def sanitized_question_ids
    return [] if mini_test_params[:question_ids].blank?

    mini_test_params[:question_ids]
      .select { |id| id.to_s =~ /\A\d+\z/ }
      .map(&:to_i)
  end
end
