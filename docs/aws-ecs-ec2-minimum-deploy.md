# AWS 本番デプロイ手順（ECS on EC2 最小構成）

このドキュメントは、`kokushiEX3` を AWS に最小構成でデプロイするための手順です。
前提は「オートスケーリングしない」「常時 1 Web + 1 Worker」です。

Terraform 定義は `infra/terraform` に配置しています。
Identity Center の初期設定手順は `docs/aws-identity-center-bootstrap.md` を参照してください。
今回の実施ログ（詰まりどころと対処）は `docs/aws-prod-deploy-log-2026-02.md` を参照してください。

## 1. 構成（最小）

- ECS Cluster: 1つ
- ECS Capacity Provider: EC2（常時1台）
- ECS Service（Web）: Desired Count = 1
- ECS Service（Worker/Sidekiq）: Desired Count = 1
- RDS PostgreSQL: 1インスタンス
- ElastiCache Redis: 1ノード
- ALB: 1台（origin）
- Cloudflare DNS: 独自ドメイン管理
- AWS WAF: Web ACL を ALB に関連付け

補足:
- Rails は Hotwire 構成のため、`web` コンテナがフロント配信とバックエンド API を兼ねます。
- `worker` は `bundle exec sidekiq` を実行します。

## 2. 事前準備

- AWS アカウント
- Cloudflare Registrar / DNS で管理する独自ドメイン（例: `kokushiex.com`）
- GitHub Actions を使う場合は OIDC 連携または IAM ユーザーキー
- Docker イメージは `Dockerfile.prod` を使用

## 3. ネットワーク

1. VPC を作成
2. Public Subnet を 2つ作成（ALB 用）
3. Private Subnet を 2つ作成（ECS/RDS/Redis 用）
4. NAT Gateway を作成（Private から外向き通信が必要なため）
5. Security Group を分離
6. ALB SG: `443` を `0.0.0.0/0` から許可
7. ECS SG: ALB SG から `3000` を許可
8. RDS SG: ECS SG から `5432` を許可
9. Redis SG: ECS SG から `6379` を許可

## 4. データストア

1. RDS PostgreSQL を作成
2. DB 名とユーザーを作成
3. ElastiCache Redis（Redis OSS）を作成
4. 接続情報を Secrets Manager / SSM Parameter Store に保存

推奨シークレット:
- `DATABASE_URL`
- `REDIS_URL`
- `SECRET_KEY_BASE`
- `RAILS_MASTER_KEY`（使う場合）
- `SIDEKIQ_USERNAME`
- `SIDEKIQ_PASSWORD`
- `SENTRY_DSN`
- `SENDGRID_API_KEY`（SendGrid継続時）または SES 用設定

## 5. コンテナイメージ

1. ECR リポジトリを作成（例: `kokushiex-web`）
2. `Dockerfile.prod` でビルド
3. ECR に push

イメージ例:
- `123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/kokushiex-web:20260222-1`

## 6. ECS（on EC2）

1. ECS Cluster を作成
2. EC2 Auto Scaling Group を作成（最小=1, 最大=1）
3. Capacity Provider として Cluster に紐付け
4. Task Definition を2つ作成
5. Web Task: `bundle exec puma -C config/puma.rb`
6. Worker Task: `bundle exec sidekiq`
7. ECS Service を2つ作成
8. Web Service を ALB Target Group に接続（port 3000）
9. Worker Service は ALB 非接続

必須環境変数（両サービス共通）:
- `RAILS_ENV=production`
- `RACK_ENV=production`
- `DATABASE_URL`
- `REDIS_URL`
- `SECRET_KEY_BASE`

Web 追加:
- `RAILS_LOG_TO_STDOUT=true`
- `RAILS_SERVE_STATIC_FILES=true`

## 7. ALB + Cloudflare DNS（独自ドメイン）

1. Terraform apply 後に ALB DNS 名を確認（`alb_dns_name` output）
2. Cloudflare DNS に CNAME を作成
3. Name: `app`
4. Target: `<alb_dns_name>`
5. 必要に応じて Cloudflare Proxy を有効化
6. ALB HTTPSを使う場合は `alb_certificate_arn` を設定して Terraform apply
7. Cloudflare の SSL/TLS モードを `Full (strict)` に設定

推奨:
- 本番: `app.kokushiex.com`
- 管理: `admin.kokushiex.com`（将来分離する場合）

## 8. WAF 設定（ALBに関連付け）

1. AWS WAF で Web ACL を作成（Scope: Regional）
2. ALB に Web ACL を関連付け
3. マネージドルールを有効化
4. `AWSManagedRulesCommonRuleSet`
5. `AWSManagedRulesKnownBadInputsRuleSet`
6. `AWSManagedRulesAmazonIpReputationList`
7. 必要に応じて `AWSManagedRulesBotControlRuleSet`（有料）を追加
8. まずは `Count` モードで誤検知確認後、`Block` に切り替え

## 9. Rails 側で要確認の本番設定

現状コードでは、以下を確認/反映してください。

1. `config/environments/production.rb`
2. `config.public_file_server.enabled` を有効化（`RAILS_SERVE_STATIC_FILES` と整合）
3. メール送信設定（SendGrid or SES）を追加
4. `config.action_mailer.default_url_options` に本番ホストを設定

補足:
- 既存の `config/database.yml` は `DATABASE_URL` を利用するため AWS でもそのまま使えます。

## 10. 初回デプロイ手順

1. ECR へイメージ push
2. ECS Task Definition を新リビジョン登録
3. Web/Worker サービスを新リビジョンへ更新
4. `rails db:migrate` を一度実行
5. 必要に応じて `rails db:seed_fu` を実行
6. アプリ疎通確認
7. ユーザー登録 / ログイン / 受験 / 結果表示
8. `/sidekiq` の管理者保護確認

## 11. 運用チェック

- CloudWatch Logs で Web/Worker ログ監視
- RDS/ElastiCache のメトリクス監視
- WAF の Block/Count ログ確認
- Sentry エラー監視

## 12. 方針メモ（今回）

- Sidekiq Worker は ECS Service で常駐運用する
- AWS Batch は採用しない（Sidekiq の常駐モデルと適合しないため）
- スケールは当面固定（`web=1`, `worker=1`）
