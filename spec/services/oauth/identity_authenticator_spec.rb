require 'rails_helper'

RSpec.describe Oauth::IdentityAuthenticator do
  subject(:result) { described_class.new(auth:, current_user:).call }

  let(:current_user) { nil }
  let(:auth) { auth_hash }

  def auth_hash(**overrides)
    attributes = {
      provider: 'developer', uid: 'uid-123',
      email: 'user@example.com',
      email_verified: true,
      profile_verified: nil,
      name: 'OAuth User', image: 'https://example.com/avatar.png'
    }.merge(overrides)
    info = auth_info(attributes)
    OmniAuth::AuthHash.new(provider: attributes[:provider], uid: attributes[:uid], info:,
                           extra: { raw_info: attributes[:raw_info] })
  end

  def auth_info(attributes)
    {
      email: attributes[:email],
      name: attributes[:name],
      image: attributes[:image],
      email_verified: attributes[:email_verified],
      verified: attributes[:profile_verified]
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

        context 'OAuth emailに大文字や空白が含まれる場合' do
          let(:auth) { auth_hash(email: ' USER@EXAMPLE.COM ') }

          it '正規化して既存ユーザーへ自動連携する' do
            expect { result }.to change(user.user_identities, :count).by(1)
            expect(result).to be_success
            expect(result.user).to eq user
          end
        end

        context '既存ユーザーのemailに大文字が含まれる場合' do
          before do
            ActiveRecord::Base.connection.execute(
              "UPDATE users SET email = 'USER@example.com' WHERE id = #{user.id}"
            )
          end

          it '大文字小文字を区別せず既存ユーザーへ自動連携する' do
            expect { result }.to change(user.user_identities, :count).by(1)
            expect(result).to be_success
            expect(result.user).to eq user
          end
        end

        context '大文字小文字違いのemailを持つ既存ユーザーが複数いる場合' do
          before do
            ActiveRecord::Base.connection.execute(
              "UPDATE users SET email = 'USER@example.com' WHERE id = #{user.id}"
            )
            create(:user, email: 'other@example.com').tap do |other_user|
              ActiveRecord::Base.connection.execute(
                "UPDATE users SET email = 'user@example.com' WHERE id = #{other_user.id}"
              )
            end
          end

          it '自動連携も新規作成もしない' do
            expect { result }.not_to(change { [User.count, UserIdentity.count] })
            expect(result).not_to be_success
          end
        end
      end

      context 'email verifiedを確認できない場合' do
        let!(:user) { create(:user, email: 'user@example.com') }
        let(:auth) { auth_hash(email_verified: false) }

        it 'emailが一致しても自動連携も新規作成もしない' do
          expect { result }.not_to change(UserIdentity, :count)
          expect(result).not_to be_success
          expect(user.reload.user_identities).to be_empty
        end
      end

      context 'email_verifiedがnilの場合' do
        let(:auth) { auth_hash(email_verified: nil) }

        it '新規ユーザーを作成しない' do
          expect { result }.not_to change(User, :count)
          expect(result).not_to be_success
        end
      end

      context 'プロフィールのverifiedのみtrueの場合' do
        let!(:user) { create(:user, email: 'user@example.com') }
        let(:auth) { auth_hash(email_verified: false, profile_verified: true) }

        it 'email verifiedとは見なさず自動連携も新規作成もしない' do
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
        it '新規ユーザーと外部アカウントを作成して成功する' do
          expect { result }.to change(User, :count).by(1).and change(UserIdentity, :count).by(1)
          expect(result).to be_success
          expect(result.user.email).to eq 'user@example.com'
          expect(result.user.username).to eq 'OAuth User'
          expect(result.user.encrypted_password).to be_present
          expect(result.identity).to have_attributes(
            user: result.user,
            provider: 'developer',
            uid: 'uid-123',
            email: 'user@example.com',
            name: 'OAuth User',
            image_url: 'https://example.com/avatar.png'
          )
        end

        context 'OAuth emailに大文字や空白が含まれる場合' do
          let(:auth) { auth_hash(email: ' NEW_USER@EXAMPLE.COM ') }

          it '正規化したemailで新規ユーザーを作成する' do
            expect(result).to be_success
            expect(result.user.email).to eq 'new_user@example.com'
          end
        end

        context 'raw_info.email_verifiedがtrueの場合' do
          let(:auth) do
            auth_hash(email_verified: false, raw_info: { email: 'user@example.com', email_verified: true })
          end

          it 'email verifiedとして新規ユーザーを作成する' do
            expect { result }.to change(User, :count).by(1).and change(UserIdentity, :count).by(1)
            expect(result).to be_success
          end
        end

        context 'raw_info.verified_emailがtrueの場合' do
          let(:auth) do
            auth_hash(email_verified: false, raw_info: { email: 'user@example.com', verified_email: true })
          end

          it 'email verifiedとして新規ユーザーを作成する' do
            expect { result }.to change(User, :count).by(1).and change(UserIdentity, :count).by(1)
            expect(result).to be_success
          end
        end

        context 'raw_infoのemailとinfoのemailが一致しない場合' do
          let(:auth) do
            auth_hash(
              email_verified: false,
              raw_info: { email: 'other@example.com', email_verified: true }
            )
          end

          it 'email verifiedとは見なさず新規ユーザーを作成しない' do
            expect { result }.not_to(change { [User.count, UserIdentity.count] })
            expect(result).not_to be_success
          end
        end

        context 'nameが取得できない場合' do
          let(:auth) { auth_hash(name: nil) }

          it 'provider名からusernameを生成する' do
            expect(result).to be_success
            expect(result.user.username).to eq 'Developerユーザー'
          end
        end

        context 'usernameが重複する場合' do
          before { create(:user, username: 'OAuth User') }

          it 'suffixを付けたusernameを生成する' do
            expect(result).to be_success
            expect(result.user.username).to eq 'OAuth User_2'
          end
        end

        context 'usernameが50文字を超える場合' do
          let(:long_name) { 'a' * 60 }
          let(:auth) { auth_hash(name: long_name) }

          it '50文字以内に切り詰める' do
            expect(result).to be_success
            expect(result.user.username.length).to eq 50
          end
        end

        context '50文字のusernameが重複する場合' do
          let(:long_name) { 'a' * 50 }
          let(:auth) { auth_hash(name: long_name) }

          before { create(:user, username: long_name) }

          it 'suffix込みで50文字以内に収める' do
            expect(result).to be_success
            expect(result.user.username).to eq "#{'a' * 48}_2"
            expect(result.user.username.length).to eq 50
          end
        end

        context 'UserCreatorが失敗した場合' do
          before do
            creator = instance_double(Oauth::UserCreator)
            allow(creator).to receive(:call).and_raise(ActiveRecord::RecordInvalid.new(build(:user_identity)))
            allow(Oauth::UserCreator).to receive(:new).and_return(creator)
          end

          it '失敗する' do
            expect { result }.not_to change(User, :count)
            expect(result).not_to be_success
          end
        end

        context '同時実行で先にUserIdentityが作成された場合' do
          let!(:user) { create(:user, email: 'race@example.com') }
          let(:association) { instance_double(ActiveRecord::Associations::CollectionProxy) }
          let(:auth) { auth_hash(email: 'race@example.com') }

          before do
            allow(UserIdentity).to receive(:find_by).and_call_original
            allow(UserIdentity).to receive(:find_by).with(provider: 'developer', uid: 'uid-123')
                                                    .and_return(nil, create(:user_identity,
                                                                            user:,
                                                                            provider: 'developer',
                                                                            uid: 'uid-123'))
            allow(user).to receive(:user_identities).and_return(association)
            allow(association).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)
          end

          it '作成済みidentityを再取得して成功する' do
            expect(result).to be_success
            expect(result.user).to eq user
          end
        end

        context '同時実行で先に同じemailのUserが作成された場合' do
          before do
            creator = instance_double(Oauth::UserCreator)
            allow(creator).to receive(:call) do
              create(:user, email: 'user@example.com')
              raise ActiveRecord::RecordNotUnique
            end
            allow(Oauth::UserCreator).to receive(:new).and_return(creator)
          end

          it '作成済みユーザーへidentityを連携して成功する' do
            expect { result }.to change(UserIdentity, :count).by(1)
            expect(result).to be_success
            expect(result.user.email).to eq 'user@example.com'
          end
        end

        context '永続化エラー後に大小違いemailの既存ユーザーが複数見つかる場合' do
          before do
            creator = instance_double(Oauth::UserCreator)
            allow(creator).to receive(:call) do
              create(:user, email: 'user@example.com')
              create(:user, email: 'other@example.com').tap do |other_user|
                ActiveRecord::Base.connection.execute(
                  "UPDATE users SET email = 'USER@example.com' WHERE id = #{other_user.id}"
                )
              end
              raise ActiveRecord::RecordNotUnique
            end
            allow(Oauth::UserCreator).to receive(:new).and_return(creator)
          end

          it '自動連携せず失敗する' do
            expect { result }.not_to change(UserIdentity, :count)
            expect(result).not_to be_success
            expect(result.message).to eq I18n.t('oauth.identity_authenticator.ambiguous_email')
          end
        end
      end

      context '同じemailの既存ユーザーがゲストの場合' do
        let!(:guest_user) { create(:user, :guest, email: 'guest_user@example.com') }
        let(:auth) { auth_hash(email: guest_user.email) }

        it 'ゲストユーザーへ自動連携せず、新規ユーザーも作成しない' do
          expect { result }.not_to(change { [User.count, UserIdentity.count] })
          expect(result).not_to be_success
          expect(guest_user.reload.user_identities).to be_empty
        end
      end
    end
  end
end
