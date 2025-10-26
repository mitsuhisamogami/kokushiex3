require 'rails_helper'

RSpec.describe 'Examinations' do
  describe 'GET /examinations/:id' do
    let(:user) { create(:user) }
    let(:test) { create(:test) }
    let(:test_session) { create(:test_session, test:) }
    let(:examination) { create(:examination, test:, user:) }
    let!(:pass_mark) { create(:pass_mark, test:) }
    let!(:score) { create(:score, examination:) }
    let!(:question) { create(:question, test_session:) }
    let!(:choice) { create(:choice, question:) }
    let!(:user_response) { create(:user_response, examination:, choice:) }

    context '自分のexaminationにアクセスする場合' do
      before do
        sign_in user
      end

      it '正常にアクセスできる' do
        get examination_path(examination)
        expect(response).to have_http_status(:ok)
      end
    end

    context '他人のexaminationにアクセスしようとする場合' do
      let(:other_user) { create(:user) }
      let(:other_examination) { create(:examination, test:, user: other_user) }

      before do
        sign_in other_user
      end

      it 'アラートと共にリダイレクトされる' do
        get examination_path(examination)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('指定されたデータが見つかりませんでした。')
      end
    end

    context '未ログインの場合' do
      it 'サインインページにリダイレクトされる' do
        get examination_path(examination)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
