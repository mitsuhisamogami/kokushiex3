require 'rails_helper'

RSpec.describe 'MiniTests' do
  describe 'GET /index' do
    let(:test) { create(:test) }
    let(:test_session) { create(:test_session, test:) }
    let(:tag) { create(:tag) }
    let!(:question) { create(:question, test_session:) }
    let!(:question_tag) { create(:question_tag, question:, tag:) }

    context 'タグを指定している場合' do
      let(:params) do
        {
          search: {
            tag_ids: [tag.id],
            question_count: 10
          }
        }
      end

      it 'returns http success' do
        get('/mini_tests', params:)
        expect(response).to have_http_status(:success)
      end
    end

    context 'タグを指定していない場合' do
      let(:params) do
        {
          search: {
            tag_ids: nil,
            question_count: 10
          }
        }
      end

      it 'test/selectにリダイレクトする' do
        get('/mini_tests', params:)
        expect(response).to redirect_to(tests_select_path)
      end
    end

    context '不正なパラメータが送信された場合' do
      it 'tag_idsに不正な文字列が含まれる場合、不正な値は除外され有効なtagのquestionのみが検索される' do
        # 別のtagと紐づくquestionを作成
        another_tag = create(:tag)
        another_question = create(:question, test_session:)
        create(:question_tag, question: another_question, tag: another_tag)

        invalid_params = {
          search: {
            tag_ids: [tag.id.to_s, 'invalid', 'abc123', another_tag.id.to_s],
            question_count: 10
          }
        }
        get('/mini_tests', params: invalid_params)
        expect(response).to have_http_status(:success)
        # 有効なtag_idsのみで検索が実行され、不正な文字列は含まれない
        question_ids = assigns(:questions).pluck(:id)
        expect(question_ids).to include(question.id, another_question.id)
        expect(question_ids).not_to include('invalid', 'abc123')
      end

      it '問題数が上限を超えている場合はバリデーションエラーでリダイレクトされる' do
        invalid_params = {
          search: {
            tag_ids: [tag.id],
            question_count: 300
          }
        }
        get('/mini_tests', params: invalid_params)
        expect(response).to redirect_to(tests_select_path)
        expect(flash[:alert]).to include('問題数は1〜200の整数で指定してください')
      end
    end
  end

  describe 'POST /create' do
    let(:test) { create(:test) }
    let(:test_session) { create(:test_session, test:) }
    let!(:questions) { create_list(:question, 3, test_session:) }
    let(:choice_ids) { questions.flat_map { |q| create(:choice, question: q).id } }

    context '正常なパラメータの場合' do
      it 'turbo_streamレスポンスを返す' do
        params = {
          user_response: {
            choice_ids: choice_ids.map(&:to_s)
          },
          question_ids: questions.map(&:id)
        }
        post('/mini_tests', params:, headers: { 'Accept' => 'text/vnd.turbo-stream.html' })
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      end
    end

    context '不正なパラメータが送信された場合' do
      it '不正な文字列が含まれるIDは除外され、有効な整数IDのみで処理される' do
        valid_choice_id = choice_ids.first
        valid_question_id = questions.first.id

        params = {
          user_response: {
            choice_ids: [valid_choice_id.to_s, 'invalid', 'abc']
          },
          question_ids: [valid_question_id.to_s, 'invalid', 'xyz123']
        }

        post('/mini_tests', params:, headers: { 'Accept' => 'text/vnd.turbo-stream.html' })
        expect(response).to have_http_status(:success)

        # 有効なIDのみで検索が実行されることを確認
        expect(assigns(:selected_answers)).to be_a(Hash)
        expect(assigns(:questions).pluck(:id)).to contain_exactly(valid_question_id)
      end
    end
  end
end
