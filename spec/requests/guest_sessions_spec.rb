require 'rails_helper'

RSpec.describe 'ゲストユーザーのログアウト', type: :request do
  let(:guest_user) { create(:user, :guest) }
  let(:exam_limit) { 5 }

  before do
    sign_in guest_user
  end

  describe 'DELETE /users/sign_out' do
    context '受験回数が上限未満の場合' do
      it 'ゲストユーザーは削除されない' do
        delete destroy_user_session_path
        expect(User.exists?(guest_user.id)).to be true
      end
    end

    context '受験回数が上限に達している場合' do
      before do
        create_list(:examination, exam_limit, user: guest_user)
      end

      it 'ログアウト後にゲストユーザーが削除される' do
        delete destroy_user_session_path
        expect(User.exists?(guest_user.id)).to be false
      end
    end
  end
end
