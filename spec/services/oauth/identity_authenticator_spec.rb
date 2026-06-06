require 'rails_helper'

RSpec.describe Oauth::IdentityAuthenticator do
  subject(:result) { described_class.new(auth:, current_user:).call }

  let(:current_user) { nil }
  let(:auth) { auth_hash }

  def auth_hash(provider: 'developer', uid: 'uid-123', email: 'user@example.com', email_verified: true,
                profile_verified: nil)
    info = auth_info(email:, email_verified:, profile_verified:)
    OmniAuth::AuthHash.new(provider:, uid:, info:)
  end

  def auth_info(email:, email_verified:, profile_verified:)
    {
      email:,
      name: 'OAuth User',
      image: 'https://example.com/avatar.png',
      email_verified:,
      verified: profile_verified
    }
  end

  context '既存のproviderとuidがある場合' do
    let(:identity) { create(:user_identity, provider: 'developer', uid: 'uid-123') }

    before { identity }

    it '未ログイン時は紐づくユーザーで成功する' do
      expect(result).to be_success
      expect(result.user).to eq identity.user
    end

    context '同じユーザーでログイン中の場合' do
      let(:current_user) { identity.user }

      it '成功扱いにする' do
        expect(result).to be_success
        expect(result.identity).to eq identity
      end
    end

    context '別ユーザーでログイン中の場合' do
      let(:current_user) { create(:user) }

      it '連携せず失敗する' do
        expect(result).not_to be_success
        expect(current_user.user_identities).to be_empty
      end
    end

    context 'ゲストユーザーに紐づくidentityの場合' do
      let(:identity) { create(:user_identity, user: create(:user, :guest), provider: 'developer', uid: 'uid-123') }

      it '未ログイン時でもゲストユーザーとしてログインしない' do
        expect(result).not_to be_success
        expect(result.user).to be_nil
      end
    end
  end

  context '既存のproviderとuidがない場合' do
    context 'ログイン中の場合' do
      let(:current_user) { create(:user) }

      it 'ログイン中ユーザーに外部アカウントを連携する' do
        expect { result }.to change(current_user.user_identities, :count).by(1)
        expect(result).to be_success
        expect(result.identity.email).to eq 'user@example.com'
      end

      context 'emailが取得できない場合' do
        let(:auth) { auth_hash(email: nil, email_verified: false) }

        it 'ログイン中ユーザーへの連携を許可する' do
          expect { result }.to change(current_user.user_identities, :count).by(1)
          expect(result).to be_success
        end
      end
    end

    context 'ゲストユーザーでログイン中の場合' do
      let(:current_user) { create(:user, :guest) }

      it '外部アカウントを連携しない' do
        expect { result }.not_to change(current_user.user_identities, :count)
        expect(result).not_to be_success
      end
    end

    context '未ログインの場合' do
      context 'email verifiedで同じemailの既存ユーザーがいる場合' do
        let!(:user) { create(:user, email: 'user@example.com') }

        it '既存ユーザーへ自動連携する' do
          expect { result }.to change(user.user_identities, :count).by(1)
          expect(result).to be_success
          expect(result.user).to eq user
        end
      end

      context 'email verifiedを確認できない場合' do
        let!(:user) { create(:user, email: 'user@example.com') }
        let(:auth) { auth_hash(email_verified: false) }

        it 'emailが一致しても自動連携しない' do
          expect { result }.not_to change(UserIdentity, :count)
          expect(result).not_to be_success
          expect(user.reload.user_identities).to be_empty
        end
      end

      context 'プロフィールのverifiedのみtrueの場合' do
        let!(:user) { create(:user, email: 'user@example.com') }
        let(:auth) { auth_hash(email_verified: false, profile_verified: true) }

        it 'email verifiedとは見なさず自動連携しない' do
          expect { result }.not_to change(UserIdentity, :count)
          expect(result).not_to be_success
          expect(user.reload.user_identities).to be_empty
        end
      end

      context 'emailが取得できない場合' do
        let(:auth) { auth_hash(email: nil) }

        it '連携も新規作成もしない' do
          expect { result }.not_to change(User, :count)
          expect(result).not_to be_success
        end
      end

      context '既存ユーザーが見つからない場合' do
        it '新規ユーザーを作成しない' do
          expect { result }.not_to change(User, :count)
          expect(result).not_to be_success
        end
      end

      context '同じemailの既存ユーザーがゲストの場合' do
        let!(:guest_user) { create(:user, :guest, email: 'guest_user@example.com') }
        let(:auth) { auth_hash(email: guest_user.email) }

        it 'ゲストユーザーへ自動連携しない' do
          expect { result }.not_to change(UserIdentity, :count)
          expect(result).not_to be_success
          expect(guest_user.reload.user_identities).to be_empty
        end
      end
    end
  end
end
