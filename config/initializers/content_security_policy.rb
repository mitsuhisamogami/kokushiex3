# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    # デフォルトは自ドメインとHTTPSのみ許可
    policy.default_src :self, :https

    # フォント: Data URIも許可（Webフォント対応）
    policy.font_src :self, :https, :data

    # 画像: Data URIとBlob URLも許可（アップロード画像やBase64エンコード対応）
    policy.img_src :self, :https, :data, :blob

    # オブジェクト埋め込み: 全て禁止（Flash等のレガシー技術対策）
    policy.object_src :none

    # スクリプト: Import Maps、Turbo、Stimulus対応
    policy.script_src :self, :https

    # スタイル: Tailwind CSSのインラインスタイル対応
    policy.style_src :self, :https

    # 開発環境でのHot Reloading対応（WebSocketとローカルホスト接続）
    if Rails.env.development?
      policy.connect_src :self, :https, "http://localhost:3035", "ws://localhost:3035"
    else
      policy.connect_src :self, :https
    end

    # フレーム: 同一オリジンのみ許可
    policy.frame_ancestors :self

    # ベースURI: 同一オリジンのみ許可（ベースタグのインジェクション対策）
    policy.base_uri :self

    # フォーム送信先: 同一オリジンとHTTPSのみ許可
    policy.form_action :self, :https
  end

  # Import Mapsとインラインスクリプト/スタイル用のnonce生成
  # セッションIDを使用することで、リクエストごとに一意な値を生成
  config.content_security_policy_nonce_generator = ->(request) {
    request.session.id.to_s
  }

  # nonceを適用するディレクティブを指定
  # script-src: Import Maps、インラインスクリプト
  # style-src: Tailwind CSSのインラインスタイル
  config.content_security_policy_nonce_directives = %w(script-src style-src)

  # 開発環境ではレポートのみ（警告を表示するが実行はブロックしない）
  # 本番環境では強制モード（違反をブロック）
  config.content_security_policy_report_only = Rails.env.development?
end
