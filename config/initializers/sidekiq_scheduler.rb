begin
  require 'sidekiq-scheduler'
rescue LoadError
  nil
end

if defined?(Sidekiq) && defined?(Sidekiq::Scheduler)
  scheduler_enabled = ENV.fetch('ENABLE_SIDEKIQ_SCHEDULER', 'true') == 'true'

  if scheduler_enabled
    Sidekiq.configure_server do |config|
      config.on(:startup) do
        Sidekiq.schedule = {
          cleanup_guest_users_job: {
            cron: '0 3 * * *',
            class: 'CleanupGuestUsersJob',
            queue: 'default',
            description: '保持期間を過ぎたゲストユーザーの削除を実行'
          }
        }
        Sidekiq::Scheduler.reload_schedule!
      end
    end
  end
end
