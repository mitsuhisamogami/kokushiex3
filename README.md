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
- **定期実行**: Render Cron Job（`cleanup:guest_users`）
- **Frontend**: Hotwire（Turbo + Stimulus）、Tailwind CSS
- **Testing**: RSpec、FactoryBot、Capybara

## セキュリティ機能

このアプリケーションには、以下のセキュリティ対策が実装されています：

- **Content Security Policy (CSP)**: XSS攻撃対策
- **Pundit**: リソースベースの認可制御
- **Rack::Attack**: レート制限によるDoS/ブルートフォース攻撃対策
- **Strong Parameters**: Mass Assignment攻撃対策
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

AWS（ECS on EC2）での最小構成デプロイ手順は以下を参照してください。

- `docs/aws-ecs-ec2-minimum-deploy.md`
- `docs/aws-identity-center-bootstrap.md`
- `docs/aws-operations-runbook.md`
- `infra/terraform/README.md`
- 構成: `web 1 + cron 1 + RDS + ALB + Cloudflare DNS + WAF`
- 注記: `docs/` と `infra/terraform/` 内には、AWS構成資料として Redis/Sidekiq 前提の記述が一部残っています（Render運用の現行構成とは別管理）。

### GitHub Actions (本番デプロイ)

- ワークフロー:
  - `.github/workflows/ci.yml`（CI: rspec / lint を並列実行）
  - `.github/workflows/reusable-ecs-deploy.yml`（共通）
  - `.github/workflows/deploy-prod.yml`（prod呼び出し）
- トリガー:
  - `workflow_dispatch`（手動実行のみ）
  - `deploy_ref` を指定して、任意ブランチ/タグのコミットをデプロイ可能
- 実行内容:
  - デプロイ開始時に ECS ASG を一時的に 2 台へスケールアウトし、終了時に元の台数へ戻す
  - 毎回 `db:migrate` を実行してからデプロイ
  - `seed_fu` は手動実行時の `run_seed=true` 指定時のみ実行（`db/fixtures/development` を使用）
- `production` Environment に設定する Secrets:
  - `AWS_ROLE_ARN`（GitHub OIDC で AssumeRole する IAM Role ARN）
- `production` Environment に設定する Variables:
  - `AWS_REGION`
  - `ECR_REPOSITORY`
  - `ECS_CLUSTER`
  - `ECS_ASG_NAME`
  - `ECS_WEB_SERVICE`
  - `ECS_WORKER_SERVICE`
  - `ECS_WEB_TASK_FAMILY`
  - `ECS_WORKER_TASK_FAMILY`
  - `ECS_WEB_CONTAINER_NAME`（任意、未設定時は `web`）
  - `ECS_WORKER_CONTAINER_NAME`（任意、未設定時は `worker`）

### 管理者ユーザー作成

```bash
ADMIN_EMAIL=your-admin@example.com ADMIN_PASSWORD=secure_password rails admin:create
```

### 環境変数

本番環境では以下の環境変数を設定してください：

- `RAILS_ENV`: `production`
- `SECRET_KEY_BASE`: Rails secret key
- `DATABASE_URL`: PostgreSQL接続URL
- その他のDevise/メール設定

## レート制限運用方針（Render）

- 当面は Render の単一インスタンス運用を前提として、`Rack::Attack` の `cache_store` に `memory_store` を使用します。
- そのため、デプロイ/再起動でレート制限カウンタはリセットされます。
- 将来、以下のいずれかに該当した時点で Redis ベースの `cache_store` 再導入を検討します。
  - Web インスタンスを複数台にスケールアウトする
  - Puma ワーカーを複数化し、プロセス間でレート制限カウンタ共有が必要になる
  - レート制限の継続性（再起動後もカウンタ保持）が運用要件になる

## ActiveJob暫定運用ルール

- 現在の `config.active_job.queue_adapter` は `:async` です。
- 定期処理は Render Cron Job から `rake` / `rails runner` で実行する方針とし、常駐ワーカーは運用しません。
- 新規機能で `perform_later` を前提にする場合は、実装前に実行基盤（Redis/外部キュー導入を含む）を再設計してください。

## ライセンス

このプロジェクトは私的利用を目的としています。
