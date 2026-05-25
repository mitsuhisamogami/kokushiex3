require 'rails_helper'

RSpec.describe 'UserResponses' do
  describe 'POST /create' do
    let(:user) { create(:user) }
    let(:test) { create(:test) }
    let(:test_session) { create(:test_session, test:) }
    let(:question) { create(:question, test_session:) }
    let(:choice_ids) { create_list(:choice, 3, question:).map(&:id) }
    let(:examination) { create(:examination, user:, test:) }
    let(:params) do
      {
        user_response: {
          test_id: test.id,
          choice_ids: choice_ids.map(&:to_s)
        }
      }
    end

    context '認証済みユーザーの場合' do
      before do
        sign_in user
      end

      context '正常系' do
        before do
          allow(Examination).to receive(:create_result!).and_return(examination)
        end

        it '受験結果が作成され、答え合わせ画面にリダイレクトされる' do
          post(user_responses_path, params:)
          expect(response).to redirect_to(examination_path(examination))
          expect(flash[:notice]).to eq '試験結果を保存しました'
        end

        it 'choice_idsが送信されない場合、未回答として空配列で採点する' do
          unanswered_params = {
            user_response: {
              test_id: test.id
            }
          }

          post(user_responses_path, params: unanswered_params)
          expect(Examination).to have_received(:create_result!).with(
            hash_including(test_id: test.id, choice_ids: [])
          )
        end
      end

      context '異常系' do
        it 'newテンプレートがレンダリングされ、エラーメッセージが表示される' do
          allow(Examination).to receive(:create_result!).and_raise(StandardError)

          post(user_responses_path, params:)
          expect(response).to redirect_to(test_path(test.id))
          expect(flash[:alert]).to eq '試験結果を保存できませんでした'
        end

        it '別試験のchoice_idが送信された場合、受験結果を保存しない' do
          other_test = create(:test)
          other_test_session = create(:test_session, test: other_test)
          other_question = create(:question, test_session: other_test_session)
          other_choice = create(:choice, question: other_question)
          invalid_params = {
            user_response: {
              test_id: test.id,
              choice_ids: [other_choice.id.to_s]
            }
          }

          expect do
            post(user_responses_path, params: invalid_params)
          end.not_to change(Examination, :count)
          expect(response).to redirect_to(test_path(test.id))
          expect(flash[:alert]).to eq '試験結果を保存できませんでした'
        end

        it '採点処理で例外が発生した場合、途中作成した受験結果と回答をロールバックする' do
          allow_any_instance_of(Score::ScoreCalculator).to receive(:call).and_raise(StandardError)
          examination_count = Examination.count
          user_response_count = UserResponse.count

          post(user_responses_path, params:)

          expect(Examination.count).to eq examination_count
          expect(UserResponse.count).to eq user_response_count
          expect(response).to redirect_to(test_path(test.id))
          expect(flash[:alert]).to eq '試験結果を保存できませんでした'
        end
      end

      context '不正なパラメータが送信された場合' do
        before do
          allow(Examination).to receive(:create_result!)
        end

        it 'choice_idsに不正な文字列が含まれる場合、空回答として扱わず保存に失敗する' do
          invalid_params = {
            user_response: {
              test_id: test.id,
              choice_ids: %w[1 invalid 2 3abc 4]
            }
          }
          post(user_responses_path, params: invalid_params)
          expect(Examination).not_to have_received(:create_result!)
          expect(response).to redirect_to(test_path(test.id))
          expect(flash[:alert]).to eq '試験結果を保存できませんでした'
        end

        it 'test_idが文字列で送信された場合でも整数に変換される' do
          params_with_string_id = {
            user_response: {
              test_id: test.id.to_s,
              choice_ids: choice_ids.map(&:to_s)
            }
          }
          post(user_responses_path, params: params_with_string_id)
          expect(Examination).to have_received(:create_result!).with(
            hash_including(test_id: test.id)
          )
        end
      end
    end

    context '未認証ユーザーの場合' do
      it 'ログインページにリダイレクトされる' do
        post(user_responses_path, params:)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
