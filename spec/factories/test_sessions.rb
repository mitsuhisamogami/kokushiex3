# == Schema Information
#
# Table name: test_sessions
#
#  id         :bigint           not null, primary key
#  session    :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  test_id    :bigint           not null
#
# Indexes
#
#  index_test_sessions_on_test_id  (test_id)
#
# Foreign Keys
#
#  fk_rails_...  (test_id => tests.id)
#
FactoryBot.define do
  factory :test_session do
    test
    session { %w[AM PM].sample } # AMまたはPMをランダムに選択
    created_at { Time.zone.now }
    updated_at { Time.zone.now }
  end
end
