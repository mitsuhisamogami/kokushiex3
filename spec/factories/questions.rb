# == Schema Information
#
# Table name: questions
#
#  id              :bigint           not null, primary key
#  content         :string           not null
#  image_url       :string
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
FactoryBot.define do
  factory :question do
    test_session
    question_number { rand(1..100) }
    content { Faker::Lorem.sentence(word_count: 3) }
  end
end
