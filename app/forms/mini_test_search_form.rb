class MiniTestSearchForm
  include ActiveModel::Model

  MAX_QUESTION_COUNT = 50
  MAX_TAG_IDS = 26
  MAX_TEST_IDS = 10
  DEFAULT_QUESTION_COUNT = 10

  attr_accessor :tag_ids, :test_ids, :question_count

  validates :tag_ids, presence: { message: 'タグを選択してください' }
  validates :question_count, numericality: {
    only_integer: true,
    greater_than: 0,
    less_than_or_equal_to: MAX_QUESTION_COUNT,
    message: "問題数は1〜#{MAX_QUESTION_COUNT}の整数で指定してください"
  }
  validate :tag_ids_within_limit
  validate :test_ids_within_limit
  validate :tag_ids_exist
  validate :test_ids_exist

  def initialize(params = {})
    permitted_params = permit_params(params)
    @tag_ids = sanitize_ids(permitted_params.dig(:search, :tag_ids))
    @test_ids = sanitize_ids(permitted_params.dig(:search, :test_ids))
    @question_count = sanitize_question_count(permitted_params.dig(:search, :question_count))
  end

  def search
    scope = Question.joins(:question_tags)
                    .where(question_tags: { tag_id: tag_ids })
                    .distinct

    if test_ids.present?
      scope = scope.joins(:test_session)
                   .where(test_sessions: { test_id: test_ids })
    end

    question_ids = scope.pluck(:id)
    Question.random_questions(question_ids, question_count)
            .includes(:choices, :tags, test_session: :test)
  end

  private

  def permit_params(params)
    if params.respond_to?(:permit)
      params.permit(search: [:question_count, { tag_ids: [], test_ids: [] }])
    else
      params
    end
  end

  def sanitize_ids(ids)
    return [] if ids.blank?

    ids.select { |id| id.to_s =~ /\A\d+\z/ }
       .map(&:to_i)
       .uniq
  end

  def sanitize_question_count(count)
    return DEFAULT_QUESTION_COUNT if count.blank?

    count.to_i
  end

  def tag_ids_within_limit
    return if tag_ids.size <= MAX_TAG_IDS

    errors.add(:tag_ids, "は#{MAX_TAG_IDS}個以下で選択してください")
  end

  def test_ids_within_limit
    return if test_ids.size <= MAX_TEST_IDS

    errors.add(:test_ids, "は#{MAX_TEST_IDS}個以下で選択してください")
  end

  def tag_ids_exist
    return if tag_ids.blank?

    existing_ids = Tag.where(id: tag_ids).pluck(:id)
    return if existing_ids.size == tag_ids.size

    errors.add(:tag_ids, 'に存在しないタグが含まれています')
  end

  def test_ids_exist
    return if test_ids.blank?

    existing_ids = Test.where(id: test_ids).pluck(:id)
    return if existing_ids.size == test_ids.size

    errors.add(:test_ids, 'に存在しない試験IDが含まれています')
  end
end
