require 'rails_helper'

RSpec.describe 'Users::omniauth_callbacks' do
  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:developer] = auth
  end

  after do
    OmniAuth.config.mock_auth[:developer] = nil
    OmniAuth.config.test_mode = false
  end

  let(:auth) do
    OmniAuth::AuthHash.new(
      provider: 'developer',
      uid: 'uid-123',
      info: {
        email: 'user@example.com',
        name: 'OAuth User',
        image: 'https://example.com/avatar.png',
        email_verified: true
      }
    )
  end

  describe 'GET /users/auth/developer/callback' do
    def callback
      get user_developer_omniauth_callback_path, env: { 'omniauth.auth' => auth }
    end

    context '既存identityがある場合' do
      let!(:identity) { create(:user_identity, provider: 'developer', uid: 'uid-123') }

      it '紐づくユーザーでログインする' do
        callback
        expect(response).to redirect_to(root_path)
        expect(controller.current_user).to eq identity.user
      end
    end

    context 'ゲストユーザーに紐づく既存identityがある場合' do
      let!(:identity) { create(:user_identity, user: create(:user, :guest), provider: 'developer', uid: 'uid-123') }

      it 'ログイン画面へ戻す' do
        callback
        expect(response).to redirect_to(new_user_session_path)
        expect(controller.current_user).to be_nil
      end
    end

    context 'ログイン中の場合' do
      let(:user) { create(:user) }

      before { sign_in user }

      it 'ログイン中ユーザーに外部アカウントを連携する' do
        expect do
          callback
        end.to change(user.user_identities, :count).by(1)

        expect(response).to redirect_to(root_path)
      end

      context '別ユーザーのidentityとして登録済みの場合' do
        before { create(:user_identity, provider: 'developer', uid: 'uid-123') }

        it 'アカウント画面へ戻す' do
          callback
          expect(response).to redirect_to(account_path)
        end
      end
    end

    context 'ゲストユーザーでログイン中の場合' do
      let(:guest_user) { create(:user, :guest) }

      before { sign_in guest_user }

      it '連携せずアカウント画面へ戻す' do
        expect do
          callback
        end.not_to change(guest_user.user_identities, :count)

        expect(response).to redirect_to(account_path)
      end
    end

    context 'verified emailの既存ユーザーがいる場合' do
      let!(:user) { create(:user, email: 'user@example.com') }

      it '既存ユーザーに自動連携してログインする' do
        expect do
          callback
        end.to change(user.user_identities, :count).by(1)

        expect(response).to redirect_to(root_path)
        expect(controller.current_user).to eq user
      end
    end

    context 'verified emailの既存ユーザーがゲストの場合' do
      let!(:guest_user) { create(:user, :guest) }
      let(:auth) do
        OmniAuth::AuthHash.new(
          provider: 'developer',
          uid: 'uid-123',
          info: {
            email: guest_user.email,
            email_verified: true
          }
        )
      end

      it '自動連携せずログイン画面へ戻す' do
        expect do
          callback
        end.not_to change(guest_user.user_identities, :count)

        expect(response).to redirect_to(new_user_session_path)
        expect(controller.current_user).to be_nil
      end
    end

    context '未ログインで認証に失敗した場合' do
      let(:auth) do
        OmniAuth::AuthHash.new(
          provider: 'developer',
          uid: 'uid-123',
          info: {
            email: 'unknown@example.com',
            email_verified: true
          }
        )
      end

      it 'ログイン画面へ戻し、新規ユーザーを作成しない' do
        expect do
          callback
        end.not_to change(User, :count)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
