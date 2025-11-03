require 'rails_helper'

RSpec.describe MiniTestSearchForm do
  let(:tag) { create(:tag) }
  let(:params) do
    {
      search: {
        tag_ids: [tag.id],
        question_count: 5 # 本来は10が最低だが絞り込みテストの件数を削減するために5に設定
      }
    }
  end
  let!(:form) { described_class.new(params) }

  describe '#new' do
    it 'params[:search]を受け取りインスタンスが生成される' do
      expect(form.tag_ids).to eq([tag.id])
      expect(form.test_ids).to eq([])
      expect(form.question_count).to eq(5)
    end

    it 'question_countが未設定の場合はデフォルト値が利用される' do
      default_form = described_class.new(search: { tag_ids: [tag.id] })
      expect(default_form.question_count).to eq(10)
    end
  end

  describe '#search' do
    let!(:question_tags) { create_list(:question_tag, 10, tag:) }

    it 'tag_idsをもとにQuestionを取得する' do
      questions = form.search
      questions.each do |q|
        expect(q.question_tags.pluck(:tag_id)).to include(tag.id)
      end
    end

    it 'question_countをもとに取得する質問数を制限する' do
      questions = form.search
      expect(questions.count).to eq(5)
    end

    it 'test_idsが指定されている場合は指定した試験に紐づく問題に絞り込む' do
      another_test = create(:test, year: '2099')
      another_session = create(:test_session, test: another_test)
      another_question = create(:question, test_session: another_session)
      create(:question_tag, question: another_question, tag:)

      scoped_form = described_class.new(search: { tag_ids: [tag.id], test_ids: [another_test.id], question_count: 5 })
      questions = scoped_form.search

      expect(questions).to all(satisfy do |question|
        question.test_session.test_id == another_test.id
      end)
    end
  end

  describe 'validation' do
    it 'タグの選択数が上限を超える場合は無効になる' do
      tag_ids = Array.new(27) { |i| create(:tag, name: "tag-#{i}").id }
      form = described_class.new(search: { tag_ids:, question_count: 10 })

      expect(form).not_to be_valid
      expect(form.errors[:tag_ids]).to include('は26個以下で選択してください')
    end

    it '試験IDの選択数が上限を超える場合は無効になる' do
      test_ids = Array.new(11) { |i| create(:test, year: "20#{i}").id }
      form = described_class.new(search: { tag_ids: [tag.id], question_count: 10, test_ids: })

      expect(form).not_to be_valid
      expect(form.errors[:test_ids]).to include('は10個以下で選択してください')
    end

    it '存在しないタグIDが含まれる場合は無効になる' do
      form = described_class.new(search: { tag_ids: [tag.id, 999_999], question_count: 10 })

      expect(form).not_to be_valid
      expect(form.errors[:tag_ids]).to include('に存在しないタグが含まれています')
    end

    it '存在しない試験IDが含まれる場合は無効になる' do
      form = described_class.new(search: { tag_ids: [tag.id], test_ids: [999_999], question_count: 10 })

      expect(form).not_to be_valid
      expect(form.errors[:test_ids]).to include('に存在しない試験IDが含まれています')
    end
  end
end
