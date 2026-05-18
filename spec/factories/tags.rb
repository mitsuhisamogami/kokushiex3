# == Schema Information
#
# Table name: tags
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_tags_on_name  (name) UNIQUE
#
FactoryBot.define do
  factory :tag do
    name { Faker::Lorem.word }

    trait :major_categories do
      id { 1 }
    end

    trait :common_tags do
      id { 4 }
    end

    trait :special_tags do
      id { 14 }
    end
  end
end
