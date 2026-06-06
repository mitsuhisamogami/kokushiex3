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
FactoryBot.define do
  factory :user_identity do
    user
    provider { 'developer' }
    sequence(:uid) { |n| "uid-#{n}" }
    sequence(:email) { |n| "identity#{n}@example.com" }
    name { 'OAuth User' }
    image_url { 'https://example.com/avatar.png' }
  end
end
