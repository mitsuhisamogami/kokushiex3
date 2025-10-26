namespace :admin do
  desc '管理者ユーザーを作成'
  task create: :environment do
    email = ENV.fetch('ADMIN_EMAIL', 'admin@example.com')
    password = ENV.fetch('ADMIN_PASSWORD') do
      raise ArgumentError, 'ADMIN_PASSWORD環境変数が設定されていません'
    end

    User.create!(
      username: '管理者',
      email: email,
      password: password,
      password_confirmation: password,
      admin: true,
      confirmed_at: Time.current
    )

    puts "管理者ユーザーを作成しました: #{email}"
  rescue ActiveRecord::RecordInvalid => e
    puts "エラー: #{e.message}"
    exit 1
  end
end
