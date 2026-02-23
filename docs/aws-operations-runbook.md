# AWS 運用手順書（バックアップ/障害対応/ローテーション）

このドキュメントは `kokushiEX3` 本番環境（AWS + Cloudflare）の運用手順をまとめたものです。  
対象環境は `production`（AWSアカウント `164249020242`、リージョン `ap-northeast-1`）です。

最終更新: 2026-02-23

## 1. 対象構成

- ECS on EC2
  - Cluster: `kokushiex-prod-ecs-cluster`
  - Service: `kokushiex-prod-web`, `kokushiex-prod-worker`
- ALB: `kokushiex-prod-alb`
- RDS PostgreSQL: `kokushiex-prod-db`
- ElastiCache Redis: `kokushiexprodredis`
- ECR: `kokushiex-prod-app`
- Cloudflare DNS: `app.kokushiex.com` -> ALB CNAME
- 監視: CloudWatch Alarm + SNS（`kokushiex-prod-alerts`）

---

## 2. バックアップ方針

## 2.1 RDS（最重要）

- 現状確認項目:
  - `backup_retention_period`
  - `backup_window`
  - `deletion_protection`
  - `skip_final_snapshot`
- 推奨方針:
  - `backup_retention_period`: 最低 7 日（可能なら 14〜35 日）
  - `deletion_protection`: `true`
  - `skip_final_snapshot`: `false`（本番削除時）
  - 週次で手動スナップショットを取得

手動スナップショット例:

```bash
aws rds create-db-snapshot \
  --db-instance-identifier kokushiex-prod-db \
  --db-snapshot-identifier kokushiex-prod-db-manual-$(date +%Y%m%d-%H%M) \
  --profile kokushiex-prod \
  --region ap-northeast-1
```

## 2.2 Redis

- Redis はキャッシュ/ジョブキュー用途（永続データの正本ではない）
- 障害時は再作成前提で運用（必要に応じて snapshot 設定を後で強化）

## 2.3 アプリ/インフラ定義

- アプリコード: GitHub（main）
- インフラ定義: Terraform（`infra/terraform`）
- ECR イメージはタグ（SHA）で追跡可能

---

## 3. 復旧手順（RDS 障害時）

## 3.1 切り分け

1. CloudWatch Alarm / SNS 通知を確認
2. RDS ステータス確認
3. ECS タスクログ、アプリエラーログ確認

確認コマンド:

```bash
aws rds describe-db-instances \
  --db-instance-identifier kokushiex-prod-db \
  --profile kokushiex-prod \
  --region ap-northeast-1 \
  --query 'DBInstances[0].{Status:DBInstanceStatus,Endpoint:Endpoint.Address,Engine:Engine,EngineVersion:EngineVersion}'
```

## 3.2 直近スナップショットから復元（必要時）

1. 最新の利用可能スナップショットを特定
2. 新規DBとして復元
3. アプリ接続先（Secretsの `DATABASE_URL`）を更新
4. ECS `web/worker` を再デプロイ

注意:
- 既存DBを直接上書きせず、新規復元して切り替える
- 切り替え前後で簡易スモークテストを実施

---

## 4. 障害時ランブック（一次対応）

## 4.1 まず確認する順序

1. `https://app.kokushiex.com` 応答コード
2. ECS `running/desired/pending`
3. ALB Target Health
4. CloudWatch Logs（web/worker）
5. RDS / Redis の状態

主要コマンド:

```bash
aws ecs describe-services \
  --cluster kokushiex-prod-ecs-cluster \
  --services kokushiex-prod-web kokushiex-prod-worker \
  --profile kokushiex-prod \
  --region ap-northeast-1 \
  --query 'services[*].{name:serviceName,running:runningCount,desired:desiredCount,pending:pendingCount}'
```

```bash
aws elbv2 describe-target-health \
  --target-group-arn "$(aws elbv2 describe-target-groups --names kokushiex-prod-web-tg --profile kokushiex-prod --region ap-northeast-1 --query 'TargetGroups[0].TargetGroupArn' --output text)" \
  --profile kokushiex-prod \
  --region ap-northeast-1
```

```bash
aws logs tail /ecs/kokushiex-prod-web \
  --since 30m \
  --profile kokushiex-prod \
  --region ap-northeast-1
```

## 4.2 よくある障害と即時対処

- `503`（Cloudflare）
  - ECS `web` 未稼働 or ALB ターゲット不健康
  - ECSイベント/ログ確認し、必要なら `update-service --force-new-deployment`
- `AccessDeniedException`（Secrets取得）
  - `ecs-task-exec-role` の IAM ポリシーを確認
- `exec format error`
  - amd64 イメージで再ビルド (`docker buildx --platform linux/amd64`)

---

## 5. シークレットローテーション手順

対象:
- DB パスワード
- `SECRET_KEY_BASE`
- `RAILS_MASTER_KEY`
- `SIDEKIQ_USERNAME` / `SIDEKIQ_PASSWORD`
- APIキー（Sentry/SendGrid など）

原則:
1. 新しい値を用意
2. Terraform 変数（または安全な注入経路）を更新
3. `terraform apply`
4. ECS 再デプロイ
5. 動作確認後に旧値を破棄

注意:
- 値の更新は必ず記録（誰が、いつ、何を）
- 手動で SecretsManager のみ変更した場合は Terraform ドリフトが出るため、最終的にIaCへ反映

---

## 6. 定期運用チェック（週次）

1. CloudWatch Alarm の発報履歴確認
2. RDS 容量・CPU・接続数の傾向確認
3. ECS タスク再起動頻度確認
4. セキュリティ更新（ベースイメージ、Gem）確認
5. 復旧訓練（少なくとも月1回、スナップショット復元手順の確認）

---

## 7. 変更管理ルール

- 本番変更は `main` マージ経由を原則
- Terraform 変更は `plan` 結果を確認してから `apply`
- 監視閾値の変更は変更理由を PR に残す
- 緊急対応後は必ず恒久対応をIssue化

---

## 8. 今後の改善課題

1. RDS バックアップ保持期間・削除保護の強化
2. AWS Backup 導入検討
3. 障害通知の二次経路（Slack/PagerDuty）追加
4. 運用ダッシュボード整備（主要メトリクス集約）
5. `db:migrate` 専用タスク定義の分離（運用安全性向上）
