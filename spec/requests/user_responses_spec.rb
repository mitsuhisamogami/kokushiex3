require 'rails_helper'

RSpec.describe 'UserResponses' do
  describe 'POST /create' do
    let(:user) { create(:user) }
    let(:test) { create(:test) }
    let(:choice_ids) { create_list(:choice, 3).map(&:id) }
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
          allow(Examination).to receive(:create_result!)
        end

        it 'user_responseが作成されリダイレクトされる' do
          post(user_responses_path, params:)
          expect(response).to redirect_to(dashboard_path)
          expect(flash[:notice]).to eq '試験結果を保存しました'
        end
      end

      context '異常系' do
        before do
          allow(Examination).to receive(:create_result!).and_raise(StandardError)
        end

        it 'newテンプレートがレンダリングされ、エラーメッセージが表示される' do
          post(user_responses_path, params:)
          expect(response).to redirect_to(test_path(test.id))
          expect(flash[:alert]).to eq '試験結果を保存できませんでした'
        end
      end

      context '不正なパラメータが送信された場合' do
        before do
          allow(Examination).to receive(:create_result!)
        end

        it 'choice_idsに不正な文字列が含まれる場合、有効な整数IDのみがフィルタリングされる' do
          invalid_params = {
            user_response: {
              test_id: test.id,
              choice_ids: %w[1 invalid 2 3abc 4]
            }
          }
          post(user_responses_path, params: invalid_params)
          expect(Examination).to have_received(:create_result!).with(
            hash_including(choice_ids: [1, 2, 4])
          )
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
