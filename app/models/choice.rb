# == Schema Information
#
# Table name: choices
#
#  id            :bigint           not null, primary key
#  content       :string           not null
#  is_correct    :boolean          default(FALSE), not null
#  option_number :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  question_id   :bigint           not null
#
# Indexes
#
#  index_choices_on_question_id  (question_id)
#
# Foreign Keys
#
#  fk_rails_...  (question_id => questions.id)
#
class Choice < ApplicationRecord
  belongs_to :question
  has_many :user_responses, dependent: :destroy

  validates :option_number, presence: true, numericality: { in: 1..5 }

  def self.mini_test_answers(choice_ids)
    where(id: choice_ids).group_by(&:question_id).transform_values { |choices| choices.map(&:option_number) }
  end
end
