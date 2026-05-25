# == Schema Information
#
# Table name: examinations
#
#  id           :bigint           not null, primary key
#  attempt_date :datetime         not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  test_id      :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_examinations_on_test_id  (test_id)
#  index_examinations_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (test_id => tests.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe Examination do
  describe '.create_result!' do
    let(:user) { create(:user) }
    let(:test) { create(:test) }
    let(:choice_ids) { create_list(:choice, 3).map(&:id) }
    let(:score_calculator_mock) { instance_double(Score::ScoreCalculator) }
    let(:params) do
      { user_id: user.id, test_id: test.id, attempt_date: DateTime.current, choice_ids: }
    end

    before do
      # UserResponse.bulk_create_responsesとScore::ScoreCalculator#callをモック
      allow(UserResponse).to receive(:bulk_create_responses).and_return(true)
      allow(Score::ScoreCalculator).to receive(:new).and_return(score_calculator_mock)
      allow(score_calculator_mock).to receive(:call)
    end

    it 'Examinationが作成され、UserResponseとScoreの処理が呼び出される' do
      # 参考：https://zenn.dev/igaiga/books/rails-practice-note/viewer/ruby_argument_literals#:~:text=%E5%BC%95%E6%95%B0%E3%82%92%E6%B8%A1%E3%81%99%E3%81%A8%E3%81%8D%E3%81%AB%E3%80%81%E3%83%8F%E3%83%83%E3%82%B7%E3%83%A5%E3%81%AE%E5%89%8D%E3%81%AB%20**%20%E3%82%92%E3%81%A4%E3%81%91%E3%81%A6%E6%B8%A1%E3%81%99%E3%81%A8%E3%80%81%E3%83%8F%E3%83%83%E3%82%B7%E3%83%A5%E3%81%AE%E5%90%84%E8%A6%81%E7%B4%A0%E3%82%92%E3%82%AD%E3%83%BC%E3%83%AF%E3%83%BC%E3%83%89%E5%BC%95%E6%95%B0%E3%81%A8%E3%81%97%E3%81%A6%E6%B8%A1%E3%81%99%E3%81%93%E3%81%A8%E3%81%8C%E3%81%A7%E3%81%8D%E3%81%BE%E3%81%99
      expect { described_class.create_result!(**params) }.to change(described_class, :count).by(1)
      expect(UserResponse).to have_received(:bulk_create_responses).with(instance_of(described_class), choice_ids)
      expect(score_calculator_mock).to have_received(:call)
    end

    it '作成したExaminationを返す' do
      result = described_class.create_result!(**params)
      expect(result).to be_a(described_class)
      expect(result).to be_persisted
    end

    context 'choice_idsが空の場合' do
      let(:choice_ids) { [] }

      it 'UserResponseを作成せず、0回答としてScoreの処理を呼び出す' do
        expect { described_class.create_result!(**params) }.to change(described_class, :count).by(1)
        expect(UserResponse).not_to have_received(:bulk_create_responses)
        expect(score_calculator_mock).to have_received(:call)
      end
    end
  end
end
