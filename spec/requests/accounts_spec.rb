require 'rails_helper'

RSpec.describe 'Accounts' do
  let(:user) { create(:user) }
  let(:guest_user) { create(:user, :guest) }

  describe 'GET /show' do
    context '通常ユーザー' do
      before { sign_in user }

      it 'returns http success' do
        get '/account'
        expect(response).to have_http_status(:success)
      end

      it 'ゲスト向けカードは表示されない' do
        get '/account'
        expect(response.body).not_to include(I18n.t('guest_upgrade_card.title'))
      end
    end

    context 'ゲストユーザー' do
      before { sign_in guest_user }

      it 'ゲスト向けカードが表示される' do
        get '/account'
        expect(response.body).to include(I18n.t('guest_upgrade_card.title'))
      end
    end
  end
end
