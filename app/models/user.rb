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
#  guest_limit_reached_at :datetime
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
#  index_users_on_confirmation_token      (confirmation_token) UNIQUE
#  index_users_on_email                   (email) UNIQUE
#  index_users_on_guest_limit_reached_at  (guest_limit_reached_at)
#  index_users_on_reset_password_token    (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  GUEST_EMAIL_PREFIX = 'guest_'.freeze
  GUEST_EMAIL_DOMAIN = '@example.com'.freeze
  GUEST_EXAM_LIMIT = 5
  GUEST_RETENTION_PERIOD = 7.days

  has_many :examinations, dependent: :destroy
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :username, presence: true, length: { maximum: 50 }
  validate :admin_restrictions

  scope :guest_users, -> { where('email LIKE ?', "#{GUEST_EMAIL_PREFIX}%#{GUEST_EMAIL_DOMAIN}") }
  scope :old_guest_users, lambda {
    guest_users.where(created_at: ...GUEST_RETENTION_PERIOD.ago)
  }

  def admin?
    admin
  end

  def self.create_guest
    unique_email = "guest_#{SecureRandom.hex(5)}@example.com"
    create do |user|
      user.email = unique_email
      user.username = 'ゲストユーザー'
      user.password = SecureRandom.urlsafe_base64
      user.guest_limit_reached_at = nil
    end
  end

  def guest?
    # ゲストユーザーのメールアドレスの型をチェック
    email.start_with?(GUEST_EMAIL_PREFIX) && email.end_with?(GUEST_EMAIL_DOMAIN)
  end

  def guest_examination_limit_reached?
    return false unless guest?

    guest_limit_reached? || examinations.count >= GUEST_EXAM_LIMIT
  end

  def guest_limit_reached?
    guest_limit_reached_at.present?
  end

  def mark_guest_limit_reached!
    return unless guest?

    update!(guest_limit_reached_at: Time.current)
  end

  # Sidekiqジョブや rake タスクから呼び出し、ゲストを削除する
  # 破壊的に削除を行い、削除した件数を返す
  def self.cleanup_old_guests!
    deleted = 0
    old_guest_users.find_each do |user|
      deleted += 1 if user.destroy
    end
    deleted
  end

  private

  def admin_restrictions
    errors.add(:admin, 'ゲストユーザーは管理者になれません') if guest? && admin?
  end
end
