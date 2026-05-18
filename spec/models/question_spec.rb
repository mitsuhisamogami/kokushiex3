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
require 'rails_helper'

RSpec.describe Question do
  let(:question) { create(:question) }

  describe '#correct_option_numbers' do
    let!(:correct_choice) { create(:choice, question:, is_correct: true) }
    let!(:incorrect_choice) { create(:choice, question:, is_correct: false) }

    it '正解の選択肢のみ配列で返される' do
      expect(question.correct_option_numbers).to eq([correct_choice.option_number])
    end
  end

  describe '#selected_option_numbers' do
    let(:examination) { create(:examination) }

    context 'questionに紐づくユーザーの回答がある場合' do
      let(:first_choice) { create(:choice, question:) }
      let(:second_choice) { create(:choice, question:) }
      let!(:first_user_response) { create(:user_response, examination:, choice: first_choice) }
      let!(:second_user_response) { create(:user_response, examination:, choice: second_choice) }

      it '回答（option_number）が配列で返される' do
        expect(question.selected_option_numbers(examination)).to eq([first_choice.option_number,
                                                                     second_choice.option_number])
      end
    end

    context 'questionに紐づく回答がない場合' do
      let(:other_question) { create(:question) }
      let(:other_choice) { create(:choice, question: other_question) }
      let(:other_response) { create(:user_response, examination:, choice: other_choice) }

      it '空の配列が返される' do
        expect(other_question.selected_option_numbers(examination)).to eq([])
      end
    end
  end

  describe '#random_questions' do
    let(:question_ids) { create_list(:question, 10).pluck(:id) }
    let(:question_count) { 5 }

    it '指定された数の質問がランダムに返される' do
      expect(described_class.random_questions(question_ids, question_count).count).to eq(question_count)
    end
  end
end
