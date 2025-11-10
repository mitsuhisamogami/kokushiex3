namespace :cleanup do
  desc '保持期間を過ぎたゲストユーザーを削除する'
  task guest_users: :environment do
    deleted_count = User.cleanup_old_guests!
    puts "Deleted #{deleted_count} old guest user(s)"
  end
end
