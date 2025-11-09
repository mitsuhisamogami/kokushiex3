# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  admin                  :boolean          default(FALSE), not null
#  confirmation_sent_at   :datetime
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
#  guest_limit_reached_at :datetime
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string(255)
#  unconfirmed_email      :string(255)
#  username               :string(255)      not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_confirmation_token      (confirmation_token) UNIQUE
#  index_users_on_email                   (email) UNIQUE
#  index_users_on_guest_limit_reached_at  (guest_limit_reached_at)
#  index_users_on_reset_password_token    (reset_password_token) UNIQUE
#
require 'rails_helper'

RSpec.describe User do
  describe '正常系' do
    it 'ユーザー登録ができる' do
      user = described_class.new(username: 'newuser', email: 'newuser@example.com', password: 'password',
                                 password_confirmation: 'password')
      expect(user).to be_valid
    end
  end

  describe '異常系' do
    context 'usernameが空の場合' do
      it 'ユーザー登録ができない' do
        user = described_class.new(username: '', email: 'newuser@example.com', password: 'password',
                                   password_confirmation: 'password')
        expect(user).not_to be_valid
      end
    end

    context 'email関連' do
      it 'emailが空の場合ユーザー登録ができない' do
        user = described_class.new(username: 'newuser', email: '', password: 'password',
                                   password_confirmation: 'password')
        expect(user).not_to be_valid
      end

      it 'emailが重複している場合ユーザー登録ができない' do
        described_class.create(username: 'newuser1', email: 'newuser@example.com', password: 'password',
                               password_confirmation: 'password')
        user2 = described_class.new(username: 'newuser2', email: 'newuser@example.com', password: 'password',
                                    password_confirmation: 'password')
        expect(user2).not_to be_valid
      end
    end

    context 'passwordが空の場合' do
      it 'ユーザー登録ができない' do
        user = described_class.new(username: 'newuser', email: 'newuser@example.com', password: '',
                                   password_confirmation: 'password')
        expect(user).not_to be_valid
      end

      it 'passwordが6文字未満の場合ユーザー登録ができない' do
        user = described_class.new(username: 'newuser', email: 'newuser@example.com', password: '12345',
                                   password_confirmation: '12345')
        expect(user).not_to be_valid
      end
    end
  end

  describe '#create_guest' do
    it 'ゲストユーザーが作成できる' do
      user = described_class.create_guest
      expect(user).to be_guest
    end
  end

  describe '#guest?' do
    subject { user.guest? }

    let(:user) { create(:user, email:) }

    context 'アドレスが指定した型の場合' do
      let(:email) { 'guest_user_new@example.com' }

      it { is_expected.to be true }
    end

    context 'アドレスが指定した型でない場合' do
      context 'guest_で始まらない場合' do
        let(:email) { 'non_guest_user@example.com' }

        it { is_expected.to be false }
      end

      context '@example.comで終わらない場合' do
        let(:email) { 'guest_user@gmail.com' }

        it { is_expected.to be false }
      end
    end
  end

  describe '.guest_users' do
    let!(:guest_user) { create(:user, :guest) }
    let!(:normal_user) { create(:user) }

    it 'ゲストアカウントのみを返す' do
      expect(described_class.guest_users).to contain_exactly(guest_user)
      expect(described_class.guest_users).not_to include(normal_user)
    end
  end

  describe '.old_guest_users' do
    let!(:fresh_guest) { create(:user, :guest, created_at: 2.days.ago) }
    let!(:stale_guest) { create(:user, :guest, created_at: 8.days.ago) }

    it '7日より古いゲストのみを返す' do
      expect(described_class.old_guest_users).to contain_exactly(stale_guest)
      expect(described_class.old_guest_users).not_to include(fresh_guest)
    end
  end

  describe '.cleanup_old_guests!' do
    let!(:stale_guest) { create(:user, :guest, created_at: 8.days.ago) }

    it '古いゲストを削除し削除件数を返す' do
      expect do
        expect(described_class.cleanup_old_guests!).to eq 1
      end.to change(described_class, :count).by(-1)
      expect(described_class.exists?(stale_guest.id)).to be false
    end
  end

  describe '#guest_examination_limit_reached?' do
    subject(:limit_reached?) { guest_user.guest_examination_limit_reached? }

    let(:guest_user) { create(:user, :guest) }

    context '受験回数が上限未満のとき' do
      before { create_list(:examination, 4, user: guest_user) }

      it { is_expected.to be false }
    end

    context '受験回数が上限に達したとき' do
      before { create_list(:examination, 5, user: guest_user) }

      it { is_expected.to be true }
    end
  end

  describe '管理者機能' do
    describe '#admin?' do
      context '管理者ユーザー' do
        it '管理者を作成できる' do
          user = create(:user, :admin)
          expect(user.admin?).to be true
        end
      end

      context '通常ユーザー' do
        it 'デフォルトでadminがfalse' do
          user = create(:user)
          expect(user.admin?).to be false
        end
      end
    end

    describe 'admin_restrictions' do
      context 'ゲストユーザー' do
        it 'ゲストユーザーは管理者になれない' do
          guest = described_class.create_guest
          guest.admin = true
          expect(guest).not_to be_valid
          expect(guest.errors[:admin]).to include('ゲストユーザーは管理者になれません')
        end
      end
    end
  end
end
