# == Schema Information
#
# Table name: tests
#
#  id         :bigint           not null, primary key
#  year       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :test do
    year { rand(2014..2024) }
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
  end
end
