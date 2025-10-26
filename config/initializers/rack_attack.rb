# frozen_string_literal: true

class Rack::Attack
  # Rack::Attackのキャッシュストア設定
  # Railsのキャッシュストアを使用（環境ごとに適切なストアが設定される）
  Rack::Attack.cache.store = Rails.cache

  # カスタムレスポンス（日本語メッセージ）
  self.throttled_responder = lambda do |_env|
    [
      429,
      { 'Content-Type' => 'text/plain' },
      ['アクセス制限に達しました。しばらく時間をおいてから再度お試しください。']
    ]
  end

  ### ユーザー登録のレート制限 ###
  # 1時間に3回まで（IP単位）
  throttle('registrations/ip', limit: 3, period: 1.hour) do |req|
    req.ip if req.path == '/users' && req.post?
  end

  ### ログイン試行のレート制限 ###
  # 5分間に5回まで（IP単位）
  throttle('logins/ip', limit: 5, period: 5.minutes) do |req|
    req.ip if req.path == '/users/sign_in' && req.post?
  end

  ### ゲストユーザー作成のレート制限 ###
  # 1時間に10回まで（IP単位）
  throttle('guest_sign_in/ip', limit: 10, period: 1.hour) do |req|
    req.ip if req.path == '/users/guest_sign_in' && req.post?
  end

  ### 試験提出のレート制限 ###
  # 5分間に1回まで（ユーザー単位）
  throttle('user_responses/user', limit: 1, period: 5.minutes) do |req|
    if req.path == '/user_responses' && req.post?
      # セッションからユーザーIDを取得
      # Deviseのwarden経由でユーザーIDを取得
      req.env['warden']&.user&.id
    end
  end
end
