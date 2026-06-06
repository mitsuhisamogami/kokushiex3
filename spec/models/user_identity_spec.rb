# == Schema Information
#
# Table name: user_identities
#
#  id         :bigint           not null, primary key
#  email      :string
#  image_url  :string
#  name       :string
#  provider   :string           not null
#  uid        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_user_identities_on_provider_and_uid      (provider,uid) UNIQUE
#  index_user_identities_on_user_id               (user_id)
#  index_user_identities_on_user_id_and_provider  (user_id,provider) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe UserIdentity do
  describe 'バリデーション' do
    subject(:identity) { build(:user_identity) }

    it '有効な外部アカウント連携を作成できる' do
      expect(identity).to be_valid
    end

    it 'providerが必須' do
      identity.provider = nil
      expect(identity).not_to be_valid
    end

    it 'uidが必須' do
      identity.uid = nil
      expect(identity).not_to be_valid
    end

    it 'providerとuidの組み合わせは一意' do
      create(:user_identity, provider: 'developer', uid: 'same-uid')
      duplicate = build(:user_identity, provider: 'developer', uid: 'same-uid')
      expect(duplicate).not_to be_valid
    end

    it 'user_idとproviderの組み合わせは一意' do
      user = create(:user)
      create(:user_identity, user:, provider: 'developer')
      duplicate = build(:user_identity, user:, provider: 'developer')
      expect(duplicate).not_to be_valid
    end
  end
end
