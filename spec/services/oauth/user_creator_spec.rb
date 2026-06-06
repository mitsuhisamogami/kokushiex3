require 'rails_helper'

RSpec.describe Oauth::UserCreator do
  subject(:creator) do
    described_class.new(
      provider: 'developer',
      uid: 'uid-123',
      email: 'user@example.com',
      name: 'OAuth User',
      image_url: 'https://example.com/avatar.png'
    )
  end

  describe '#call' do
    context 'UserIdentityの作成に失敗した場合' do
      before { create(:user_identity, provider: 'developer', uid: 'uid-123') }

      it '新規ユーザーをロールバックする' do
        user_count = User.count

        expect { creator.call }.to raise_error(ActiveRecord::RecordInvalid)
        expect(User.count).to eq user_count
      end
    end
  end
end
