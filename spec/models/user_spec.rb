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
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
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
