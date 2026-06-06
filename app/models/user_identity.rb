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
class UserIdentity < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true, uniqueness: { scope: :uid }
  validates :uid, presence: true
  validates :user_id, uniqueness: { scope: :provider }
end
