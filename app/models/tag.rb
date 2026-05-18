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
class Tag < ApplicationRecord
  has_many :question_tags, dependent: :destroy
  has_many :questions, through: :question_tags

  validates :name, presence: true, uniqueness: true

  scope :common_tags, -> { where(id: 4..13) }
  scope :special_tags, -> { where(id: 14..26) }
  scope :major_categories, -> { where(id: 1..3) }
end
