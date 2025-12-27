# == Schema Information
#
# Table name: questions
#
#  id              :bigint           not null, primary key
#  content         :string(255)      not null
#  image_url       :string(255)
#  question_number :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  test_session_id :bigint           not null
#
# Indexes
#
#  index_questions_on_test_session_id  (test_session_id)
#
# Foreign Keys
#
#  fk_rails_...  (test_session_id => test_sessions.id)
#
class Question < ApplicationRecord
  belongs_to :test_session
  has_many :choices, dependent: :destroy
  has_many :question_tags, dependent: :destroy
  has_many :tags, through: :question_tags

  validates :content, presence: true
  validates :question_number, presence: true

  def correct_option_numbers
    choices.select(&:is_correct).map(&:option_number)
  end

  # questionに対応する回答を取得する
  def selected_option_numbers(examination)
    user_responses = examination.user_responses.select { |response| response.choice.question_id == id }
    user_responses.map { |response| response.choice.option_number }
  end

  def self.random_questions(question_ids, question_count)
    random_ids = question_ids.sample(question_count)
    where(id: random_ids)
  end
end
