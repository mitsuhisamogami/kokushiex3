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
    auth_hash
  end

  def auth_hash(**overrides)
    attributes = default_auth_attributes.merge(overrides)

    OmniAuth::AuthHash.new(provider: attributes[:provider], uid: attributes[:uid],
                           info: attributes.slice(:email, :email_verified, :name, :image))
  end

  def default_auth_attributes
    {
      provider: 'developer', uid: 'uid-123',
      email: 'user@example.com', email_verified: true,
      name: 'OAuth User', image: 'https://example.com/avatar.png'
    }
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
        user_count = User.count

        expect do
          callback
        end.to change(user.user_identities, :count).by(1)

        expect(User.count).to eq user_count
        expect(response).to redirect_to(root_path)
        expect(controller.current_user).to eq user
      end

      context '既存ユーザーのemailに大文字が含まれる場合' do
        before do
          ActiveRecord::Base.connection.execute(
            "UPDATE users SET email = 'USER@example.com' WHERE id = #{user.id}"
          )
        end

        it '新規ユーザーを作成せず既存ユーザーに自動連携してログインする' do
          user_count = User.count

          expect do
            callback
          end.to change(user.user_identities, :count).by(1)

          expect(User.count).to eq user_count
          expect(response).to redirect_to(root_path)
          expect(controller.current_user).to eq user
        end
      end

      context '大文字小文字違いのemailを持つ既存ユーザーが複数いる場合' do
        let!(:other_user) { create(:user, email: 'other@example.com') }

        before do
          ActiveRecord::Base.connection.execute(
            "UPDATE users SET email = 'USER@example.com' WHERE id = #{other_user.id}"
          )
        end

        it '自動連携も新規作成もせずログイン画面へ戻す' do
          expect do
            callback
          end.not_to(change { [User.count, UserIdentity.count] })

          expect(response).to redirect_to(new_user_session_path)
          expect(flash[:alert]).to eq I18n.t('oauth.identity_authenticator.ambiguous_email')
          expect(controller.current_user).to be_nil
        end
      end
    end

    context 'verified emailの既存ユーザーがゲストの場合' do
      let!(:guest_user) { create(:user, :guest) }
      let(:auth) { auth_hash(email: guest_user.email, name: nil, image: nil) }

      it '自動連携せずログイン画面へ戻す' do
        expect do
          callback
        end.not_to(change { [User.count, UserIdentity.count] })

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to eq I18n.t('oauth.identity_authenticator.guest_user_not_allowed')
        expect(controller.current_user).to be_nil
      end
    end

    context '未ログインでverified emailの既存ユーザーがいない場合' do
      let(:auth) { auth_hash(email: 'unknown@example.com', name: nil, image: nil) }

      it '新規ユーザーと外部アカウントを作成してログインする' do
        expect do
          callback
        end.to change(User, :count).by(1).and change(UserIdentity, :count).by(1)

        created_user = User.find_by(email: 'unknown@example.com')
        expect(response).to redirect_to(root_path)
        expect(controller.current_user).to eq created_user
        expect(created_user.user_identities.first).to have_attributes(
          provider: 'developer',
          uid: 'uid-123',
          email: 'unknown@example.com'
        )
      end

      context 'ユーザー作成に失敗した場合' do
        before do
          creator = instance_double(Oauth::UserCreator)
          allow(creator).to receive(:call).and_raise(ActiveRecord::RecordInvalid.new(build(:user)))
          allow(Oauth::UserCreator).to receive(:new).and_return(creator)
        end

        it 'ログイン画面へ戻し、失敗理由をflash alertに表示する' do
          expect do
            callback
          end.not_to(change { [User.count, UserIdentity.count] })

          expect(response).to redirect_to(new_user_session_path)
          expect(flash[:alert]).to eq I18n.t('oauth.identity_authenticator.signup_failed')
          expect(controller.current_user).to be_nil
        end
      end
    end

    context '未ログインでemail verifiedを確認できない場合' do
      let(:auth) { auth_hash(email: 'unknown@example.com', email_verified: false, name: nil, image: nil) }

      it 'ログイン画面へ戻し、新規ユーザーを作成しない' do
        expect do
          callback
        end.not_to(change { [User.count, UserIdentity.count] })

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to eq I18n.t('oauth.identity_authenticator.unverified_email')
        expect(controller.current_user).to be_nil
      end
    end

    context '未ログインでemail verifiedが不明な場合' do
      let(:auth) { auth_hash(email: 'unknown@example.com', email_verified: nil, name: nil, image: nil) }

      it 'ログイン画面へ戻し、失敗理由をflash alertに表示する' do
        expect do
          callback
        end.not_to(change { [User.count, UserIdentity.count] })

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to eq I18n.t('oauth.identity_authenticator.unverified_email')
        expect(controller.current_user).to be_nil
      end
    end

    context '未ログインでemailを取得できない場合' do
      let(:auth) { auth_hash(email: nil, name: nil, image: nil) }

      it 'ログイン画面へ戻し、失敗理由をflash alertに表示する' do
        expect do
          callback
        end.not_to(change { [User.count, UserIdentity.count] })

        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to eq I18n.t('oauth.identity_authenticator.unverified_email')
        expect(controller.current_user).to be_nil
      end
    end
  end
end
