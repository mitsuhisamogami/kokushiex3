# kokushiEX

## サービス概要

**国試exforPT** - 理学療法士国家試験のオンライン過去問練習サービス

### 主な機能

- **ゲスト受験**: ユーザー登録なしで過去問を受験可能
- **カスタム試験**: 年度別、午前/午後問題、タグ別で絞り込んだ試験を作成可能
- **詳細レポート**: ユーザー登録すると受験結果の詳細なレポートを確認可能
- **受験履歴**: 過去の受験結果を一覧表示し、成績推移を確認可能

## 技術スタック

- **Ruby**: 3.3.8
- **Rails**: 7.2.2.2
- **Database**: MySQL 8.4.3（開発環境）、PostgreSQL（本番環境）
- **Authentication**: Devise
- **Authorization**: Pundit
- **Rate Limiting**: Rack::Attack
- **Background Jobs**: Sidekiq + Redis
- **Frontend**: Hotwire（Turbo + Stimulus）、Tailwind CSS
- **Testing**: RSpec、FactoryBot、Capybara

## セキュリティ機能

このアプリケーションには、以下のセキュリティ対策が実装されています：

- **Content Security Policy (CSP)**: XSS攻撃対策
- **Pundit**: リソースベースの認可制御
- **Rack::Attack**: レート制限によるDoS/ブルートフォース攻撃対策
- **Strong Parameters**: Mass Assignment攻撃対策
- **管理者認証**: Sidekiq管理画面への管理者のみアクセス制限
- **Rails 7.2.2.2**: 最新のセキュリティパッチ適用済み

詳細は [CLAUDE.md](CLAUDE.md) を参照してください。

## セットアップ

### 前提条件

- Docker
- Docker Compose

### 初期セットアップ

```bash
# コンテナ起動
docker-compose up -d

# データベース作成
docker-compose exec web rails db:create

# マイグレーション実行
docker-compose exec web rails db:migrate

# シードデータ読み込み
docker-compose exec web rails db:seed_fu
```

### 開発サーバー起動

```bash
# Rails + Tailwind CSSウォッチャーを起動
docker-compose up

# または bin/dev を使用（コンテナ内で）
docker-compose exec web bin/dev
```

アプリケーションは http://localhost:3000 で起動します。

### 管理者ユーザー（開発環境）

シードデータで作成される管理者アカウント：

```
Email: admin@example.com
Password: admin123
```

## テスト

```bash
# 全テスト実行
docker-compose exec web bundle exec rspec

# 特定のテストファイル実行
docker-compose exec web bundle exec rspec spec/models/user_spec.rb

# カバレッジ付きで実行
docker-compose exec web COVERAGE=true bundle exec rspec
```

## コード品質チェック

```bash
# RuboCop実行
docker-compose exec web bundle exec rubocop

# RuboCop自動修正
docker-compose exec web bundle exec rubocop -a

# ERBファイルのLint
docker-compose exec web bundle exec erblint --lint-all
```

## データベース

### マイグレーション

```bash
docker-compose exec web rails db:migrate
```

### シードデータ

```bash
# 全シードデータ読み込み
docker-compose exec web rails db:seed_fu

# 特定のフィクスチャ読み込み
docker-compose exec web rails db:seed_fu FIXTURE_PATH=db/fixtures/development
```

## エラー監視 (Sentry)

本番環境のエラー監視には Sentry を利用します。

1. [Sentry](https://sentry.io) でプロジェクトを作成し、DSN を取得する
2. `rails credentials:edit` を実行し、`sentry_dsn: <取得した DSN>` を追記する  
   （または暫定的に `SENTRY_DSN` 環境変数を設定する）
3. 必要に応じて `SENTRY_TRACES_SAMPLE_RATE` や `SENTRY_ENVIRONMENT` を環境変数で上書きする

DSN が設定されている環境（production / staging）で自動的に Sentry が初期化されます。

## 本番環境デプロイ

### 管理者ユーザー作成

```bash
ADMIN_EMAIL=your-admin@example.com ADMIN_PASSWORD=secure_password rails admin:create
```

### 環境変数

本番環境では以下の環境変数を設定してください：

- `RAILS_ENV`: `production`
- `SECRET_KEY_BASE`: Rails secret key
- `DATABASE_URL`: PostgreSQL接続URL
- `REDIS_URL`: Redis接続URL
- その他のDevise/メール設定

## ライセンス

このプロジェクトは私的利用を目的としています。
