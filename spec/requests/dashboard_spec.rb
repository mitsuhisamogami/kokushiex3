require 'rails_helper'

RSpec.describe 'Dashboards' do
  describe 'GET /index' do
    let(:user) { create(:user) }
    let(:guest_user) { create(:user, :guest) }
    let(:test) { create(:test) }
    let!(:pass_mark) { create(:pass_mark, test:) }
    let!(:examination) { create(:examination, test:, user:) }
    let!(:score) { create(:score, examination:) }

    context '認証済みユーザーの場合' do
      before do
        sign_in user
      end

      it 'returns http success' do
        get '/dashboard'
        expect(response).to have_http_status(:success)
      end

      it 'ゲスト向けカードは表示されない' do
        get '/dashboard'
        expect(response.body).not_to include(I18n.t('guest_upgrade_card.title'))
      end
    end

    context 'ゲストユーザーの場合' do
      before { sign_in guest_user }

      it 'ゲスト向けカードが表示される' do
        get '/dashboard'
        expect(response.body).to include(I18n.t('guest_upgrade_card.title'))
      end
    end

    context '未認証ユーザーの場合' do
      it 'ログインページにリダイレクトされる' do
        get '/dashboard'
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
