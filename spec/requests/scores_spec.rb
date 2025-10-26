require 'rails_helper'

RSpec.describe 'Scores' do
  describe 'GET /examinations/:examination_id/scores/:id' do
    let(:user) { create(:user) }
    let(:test) { create(:test) }
    let(:examination) { create(:examination, test:, user:) }
    let!(:score) { create(:score, examination:) }

    context '自分のscoreにアクセスする場合' do
      before do
        sign_in user
      end

      it '正常にアクセスできる' do
        get examination_score_path(examination, score)
        expect(response).to have_http_status(:ok)
      end
    end

    context '他人のscoreにアクセスしようとする場合' do
      let(:other_user) { create(:user) }

      before do
        sign_in other_user
      end

      it 'アラートと共にリダイレクトされる' do
        get examination_score_path(examination, score)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('この操作を実行する権限がありません。')
      end
    end

    context '未ログインの場合' do
      it 'サインインページにリダイレクトされる' do
        get examination_score_path(examination, score)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
