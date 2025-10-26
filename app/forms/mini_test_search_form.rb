class MiniTestSearchForm
  include ActiveModel::Model

  attr_accessor :tag_ids, :question_count

  validates :tag_ids, presence: { message: 'タグを選択してください' }
  validates :question_count, numericality: {
    only_integer: true,
    greater_than: 0,
    less_than_or_equal_to: 200,
    message: '問題数は1〜200の整数で指定してください'
  }

  def initialize(params = {})
    permitted_params = permit_params(params)
    @tag_ids = sanitize_ids(permitted_params.dig(:search, :tag_ids))
    @question_count = sanitize_question_count(permitted_params.dig(:search, :question_count))
  end

  def search
    question_ids = Question.joins(:question_tags)
                           .where(question_tags: { tag_id: tag_ids })
                           .distinct
                           .pluck(:id)
    Question.random_questions(question_ids, question_count)
  end

  private

  def permit_params(params)
    if params.respond_to?(:permit)
      params.permit(search: [:question_count, { tag_ids: [] }])
    else
      params
    end
  end

  def sanitize_ids(ids)
    return [] if ids.blank?

    ids.select { |id| id.to_s =~ /\A\d+\z/ }.map(&:to_i)
  end

  def sanitize_question_count(count)
    return 0 if count.blank?

    count.to_i
  end
end
