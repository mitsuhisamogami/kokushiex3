require 'rails_helper'

RSpec.describe 'Users::registrations' do
  let(:user) { create(:user) }
  let(:guest_user) { create(:user, :guest, guest_limit_reached_at: Time.current) }

  describe 'GET /users/sign_up' do
    it 'ユーザー登録画面が表示される' do
      get new_user_registration_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /users/sign_up' do
    let(:valid_user_params) do
      { user: { username: 'newuser', email: 'newuser@example.com', password: 'password',
                password_confirmation: 'password' } }
    end
    let(:invalid_user_params) do
      { user: { username: '', email: 'user@example.com', password: 'password', password_confirmation: 'password' } }
    end

    context '正常系' do
      it 'ユーザー登録後ダッシュボード画面にリダイレクトされる' do
        expect do
          post user_registration_path, params: valid_user_params
        end.to change(User, :count).by(1)
        expect(response).to redirect_to(dashboard_path)
        expect(response).to have_http_status(:see_other)
      end
    end

    context '不正なパラメータの場合' do
      it 'ユーザー登録ができず新規登録画面にリダイレクトされる' do
        expect do
          post user_registration_path, params: invalid_user_params
        end.not_to change(User, :count)
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT /users' do
    context 'ゲストユーザーが本登録情報へ更新する場合' do
      let(:guest_params) do
        {
          user: {
            username: '本登録ユーザー',
            email: 'member@example.com',
            password: 'guestupdate',
            password_confirmation: 'guestupdate'
          }
        }
      end

      before { sign_in guest_user }

      it 'current_passwordなしで更新できてゲスト属性が解除される' do
        put user_registration_path, params: guest_params

        expect(response).to have_http_status(:see_other)
        expect(flash[:notice]).to eq('本登録が完了しました。これまでの試験結果を引き継いで利用できます。')

        guest_user.reload
        expect(guest_user.username).to eq('本登録ユーザー')
        expect(guest_user.email).to eq('member@example.com')
        expect(guest_user.guest?).to be(false)
        expect(guest_user.guest_limit_reached_at).to be_nil
      end
    end

    context '通常ユーザーが current_password を送らない場合' do
      let(:update_params) do
        {
          user: {
            username: '変更後ユーザー',
            email: 'changed@example.com'
          }
        }
      end

      before { sign_in user }

      it '更新に失敗する' do
        expect do
          put user_registration_path, params: update_params
        end.not_to(change { user.reload.username })

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
