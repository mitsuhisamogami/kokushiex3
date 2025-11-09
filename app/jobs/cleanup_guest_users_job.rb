class CleanupGuestUsersJob < ApplicationJob
  queue_as :default

  def perform
    deleted = User.cleanup_old_guests!
    Rails.logger.info("CleanupGuestUsersJob deleted #{deleted} old guest users")
    deleted
  end
end
