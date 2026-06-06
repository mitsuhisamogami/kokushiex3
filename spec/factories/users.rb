# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  admin                  :boolean          default(FALSE), not null
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  guest_limit_reached_at :datetime
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  unconfirmed_email      :string
#  username               :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_confirmation_token      (confirmation_token) UNIQUE
#  index_users_on_email                   (email) UNIQUE
#  index_users_on_guest_limit_reached_at  (guest_limit_reached_at)
#  index_users_on_lower_email             (lower((email)::text))
#  index_users_on_reset_password_token    (reset_password_token) UNIQUE
#  index_users_on_username                (username)
#
FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "テストユーザー#{n}" }
    email { Faker::Internet.unique.email }
    password { '12345678' }
    password_confirmation { '12345678' }
    admin { false }

    trait :admin do
      admin { true }
      username { '管理者' }
      sequence(:email) { |n| "admin#{n}@example.com" }
    end

    trait :guest do
      email { "guest_#{SecureRandom.hex(5)}@example.com" }
      username { 'ゲストユーザー' }
    end
  end
end
