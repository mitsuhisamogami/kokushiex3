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
FactoryBot.define do
  factory :user do
    username { Faker::Name.unique.name }
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
