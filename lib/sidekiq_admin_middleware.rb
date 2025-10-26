class SidekiqAdminMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    warden = env['warden']
    current_user = warden.user

    # 未ログインの場合、ログインページにリダイレクト
    return redirect_to('/users/sign_in') if current_user.nil?

    # ログイン済みだが管理者でない場合、トップページにリダイレクト
    return redirect_to('/') unless current_user.admin?

    # 管理者の場合、Sidekiq管理画面にアクセス許可
    @app.call(env)
  end

  private

  def redirect_to(path)
    [302, { 'Location' => path, 'Content-Type' => 'text/html' }, ['Redirecting...']]
  end
end
