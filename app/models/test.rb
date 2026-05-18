# == Schema Information
#
# Table name: tests
#
#  id         :bigint           not null, primary key
#  year       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Test < ApplicationRecord
  has_many :test_sessions, dependent: :destroy
  has_one :pass_mark, dependent: :destroy
  has_many :examinations, through: :test_sessions, dependent: :destroy

  validates :year, presence: true
end
