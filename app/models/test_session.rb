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
class TestSession < ApplicationRecord
  belongs_to :test
  has_many :examinations, dependent: :destroy
  has_many :questions, dependent: :destroy

  validates :session, presence: true, inclusion: { in: %w[AM PM] }
end
