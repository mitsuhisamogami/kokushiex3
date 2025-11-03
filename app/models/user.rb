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
class User < ApplicationRecord
  has_many :examinations, dependent: :destroy
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :username, presence: true, length: { maximum: 50 }
  validate :admin_restrictions

  def admin?
    admin
  end

  def self.create_guest
    unique_email = "guest_#{SecureRandom.hex(5)}@example.com"
    create do |user|
      user.email = unique_email
      user.username = 'ゲストユーザー'
      user.password = SecureRandom.urlsafe_base64
    end
  end

  def guest?
    # ゲストユーザーのメールアドレスの型をチェック
    email.start_with?('guest_') && email.end_with?('@example.com')
  end

  private

  def admin_restrictions
    errors.add(:admin, 'ゲストユーザーは管理者になれません') if guest? && admin?
  end
end
