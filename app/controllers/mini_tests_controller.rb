class MiniTestsController < ApplicationController
  MAX_QUESTIONS = 50
  MAX_CHOICES = 250

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
    unique_question_ids = validate_question_ids!(sanitized_question_ids)
    unique_choice_ids = validate_choice_ids!(sanitized_choice_ids)

    load_mini_test_resources(unique_question_ids, unique_choice_ids)

    respond_to do |format|
      format.turbo_stream
    end
  rescue ValidationError => e
    redirect_to tests_select_path, alert: e.message
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

  def load_mini_test_resources(question_ids, choice_ids)
    @questions = Question.includes(:choices, test_session: :test)
                         .where(id: question_ids)
    validate_question_existence!(question_ids, @questions)
    @selected_answers = Choice.mini_test_answers(choice_ids)
  end

  def validate_question_ids!(question_ids)
    raise ValidationError, '問題が選択されていません' if question_ids.blank?
    raise ValidationError, "問題数が多すぎます（最大#{MAX_QUESTIONS}問）" if question_ids.size > MAX_QUESTIONS

    unique_ids = question_ids.uniq
    raise ValidationError, '重複した問題IDが含まれています' if unique_ids.size != question_ids.size

    unique_ids
  end

  def validate_choice_ids!(choice_ids)
    raise ValidationError, "回答数が多すぎます（最大#{MAX_CHOICES}）" if choice_ids.size > MAX_CHOICES

    unique_ids = choice_ids.uniq
    raise ValidationError, '重複した回答IDが含まれています' if unique_ids.size != choice_ids.size

    ensure_choices_exist!(unique_ids)
  end

  def validate_question_existence!(question_ids, questions)
    return if questions.size == question_ids.size

    raise ValidationError, '存在しない問題が含まれています'
  end

  def ensure_choices_exist!(choice_ids)
    choice_ids_in_db = Choice.where(id: choice_ids).pluck(:id)
    raise ValidationError, '存在しない回答が含まれています' if choice_ids_in_db.size != choice_ids.size

    choice_ids
  end

  class ValidationError < StandardError; end
end
