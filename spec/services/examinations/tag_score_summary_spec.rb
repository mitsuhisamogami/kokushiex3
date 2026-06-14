require 'rails_helper'

RSpec.describe Examinations::TagScoreSummary do
  describe '#call' do
    subject(:summary) { described_class.new(examination).call }

    let(:test) { create(:test) }
    let(:test_session) { create(:test_session, test:) }
    let(:examination) { create(:examination, test:) }

    let(:practical_tag) { create(:tag, name: '運動療法') }
    let(:another_practical_tag) { create(:tag, name: '脳血管疾患') }
    let(:specialty_tag) { create(:tag, name: '物理療法') }
    let(:common_tag) { create(:tag, name: '解剖学') }

    let!(:practical_question) { create(:question, test_session:, question_number: 1) }
    let!(:unanswered_practical_question) { create(:question, test_session:, question_number: 20) }
    let!(:specialty_question) { create(:question, test_session:, question_number: 21) }
    let!(:common_question) { create(:question, test_session:, question_number: 51) }

    let!(:practical_choice) { create(:choice, question: practical_question, is_correct: true) }
    let!(:specialty_choice) { create(:choice, question: specialty_question, is_correct: true) }
    let!(:wrong_common_choice) { create(:choice, question: common_question, is_correct: false) }

    before do
      create(:question_tag, question: practical_question, tag: practical_tag)
      create(:question_tag, question: practical_question, tag: another_practical_tag)
      create(:question_tag, question: unanswered_practical_question, tag: practical_tag)
      create(:question_tag, question: specialty_question, tag: specialty_tag)
      create(:question_tag, question: common_question, tag: common_tag)

      create(:user_response, examination:, choice: practical_choice)
      create(:user_response, examination:, choice: specialty_choice)
      create(:user_response, examination:, choice: wrong_common_choice)
    end

    it '問題番号に基づいて区分別に集計する' do
      expect(summary.keys).to contain_exactly(:practical, :specialty, :common)
      expect(summary[:practical][:label]).to eq('実地')
      expect(summary[:specialty][:label]).to eq('専門')
      expect(summary[:common][:label]).to eq('共通')
    end

    it '実地は1問3点で未回答を0点として分母に含める' do
      practical_score = summary[:practical][:tags].find { |tag| tag[:name] == '運動療法' }

      expect(practical_score).to include(
        earned_score: 3,
        total_score: 6,
        percentage: 50
      )
    end

    it '複数タグが付いた問題は各タグに同じ点数を加算する' do
      another_score = summary[:practical][:tags].find { |tag| tag[:name] == '脳血管疾患' }

      expect(another_score).to include(
        earned_score: 3,
        total_score: 3,
        percentage: 100
      )
    end

    it '専門と共通は1問1点で集計する' do
      specialty_score = summary[:specialty][:tags].find { |tag| tag[:name] == '物理療法' }
      common_score = summary[:common][:tags].find { |tag| tag[:name] == '解剖学' }

      expect(specialty_score).to include(earned_score: 1, total_score: 1, percentage: 100)
      expect(common_score).to include(earned_score: 0, total_score: 1, percentage: 0)
    end
  end
end
