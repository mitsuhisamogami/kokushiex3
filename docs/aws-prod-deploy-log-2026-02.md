# AWS本番構築 実施ログ（2026-02）

このドキュメントは、`kokushiEX3` の AWS 本番構築時に実施した内容と、
詰まったポイント、解決策を再現できる形で残すためのログです。

最終更新: 2026-02-23

## 1. 最終到達点（完了状態）

- `https://app.kokushiex.com` が `HTTP/2 200` を返す
- ECS `web` サービス: `running=1 / desired=1`
- ALB ターゲットグループ: `healthy`
- Cloudflare DNS で `app` CNAME -> ALB の構成
- ALB は HTTPS リスナー有効（ACM証明書適用）

## 2. 今回の大きな流れ

1. AWS Organizations + IAM Identity Center を有効化
2. メンバーアカウント（`164249020242`）に Terraform 実行基盤を作成
3. Terraform で VPC/ECS/ALB/RDS/Redis/WAF/ECR を apply
4. Cloudflare で `kokushiex.com` を管理し、`app` CNAME を設定
5. ACM 証明書を DNS 検証で発行し、ALB HTTPS 化
6. `linux/amd64` イメージを ECR に push
7. ECS `web/worker` を再デプロイして疎通確認

## 3. 詰まったポイントと対処

### 3.1 Route53 Hosted Zone エラー

- 症状:
  - `terraform plan` で `no matching Route 53 Hosted Zone found`
- 原因:
  - ドメインを Cloudflare Registrar/DNS で運用する方針へ変更したため、AWS Route53 の data 参照が不整合
- 対処:
  - Terraform を Cloudflare DNS 前提に変更（Route53 依存を外す）
  - ALB の DNS 名を output し、Cloudflare 側で CNAME を作成

### 3.2 RDS バージョン固定エラー

- 症状:
  - `Cannot find version 16.3 for postgres`
- 原因:
  - 指定リージョンで当該パッチバージョンが選択不可
- 対処:
  - `rds.tf` の `engine_version` 固定を見直し、利用可能バージョンで作成

### 3.3 ECR ログインのコマンド崩れ

- 症状:
  - `Unknown options` / `cannot perform an interactive login from a non-TTY device`
- 原因:
  - 改行位置の誤りで `| docker login ...` が正しく解釈されなかった
- 対処:
  - パイプを1行で実行、またはパスワードをファイル経由で渡して実行

### 3.4 Cloudflare 521/503

- 症状:
  - `curl -I https://app.kokushiex.com` で `521` や `503`
- 原因:
  - 初期は ALB 側 HTTPS 未設定、または ECS タスク未起動
- 対処:
  - ACM 証明書を発行
  - ALB 443 リスナー作成 + 80->443 リダイレクト
  - Cloudflare SSL/TLS を `Full (strict)` で運用

### 3.5 ALB リスナー重複エラー

- 症状:
  - `DuplicateListener: A listener already exists on this port`
- 原因:
  - HTTP リスナー定義の置換タイミングで同ポート重複
- 対処:
  - Terraform 定義を整理して再 apply（最終的に解消）

### 3.6 ECS で Secrets Manager AccessDenied

- 症状:
  - `ecs-task-exec-role ... is not authorized to perform secretsmanager:GetSecretValue`
- 原因:
  - `ecs_task_execution_role` に Secrets 読み取り権限不足
- 対処:
  - IAM ポリシーを追加
  - `secretsmanager:GetSecretValue`, `DescribeSecret`, `ListSecretVersionIds`
  - 必要に応じて `kms:Decrypt`

### 3.7 Docker ビルド失敗（psych / libyaml）

- 症状:
  - `yaml.h not found`（psych gem ビルド失敗）
- 原因:
  - build stage に `libyaml-dev` が不足
- 対処:
  - `Dockerfile.prod` build stage に `libyaml-dev` を追加
  - runtime stage に `libyaml-0-2` を追加

### 3.8 buildx のプラットフォーム不一致

- 症状:
  - `Your bundle only supports platforms ... but your local platform is x86_64-linux`
- 原因:
  - `Gemfile.lock` に `x86_64-linux` が未登録
- 対処:
  - `bundle lock --add-platform x86_64-linux` を実行して lockfile 更新

### 3.9 ECS タスクの `exec format error`

- 症状:
  - `exec /usr/local/bin/bundle: exec format error`
- 原因:
  - ARMイメージを x86_64 の ECS EC2 で実行
- 対処:
  - `docker buildx build --platform linux/amd64 ... --push`
  - ECS サービスを `--force-new-deployment`

### 3.10 Docker Desktop / BuildKit I/O エラー

- 症状:
  - `write /var/lib/docker/buildkit/metadata_v2.db: input/output error`
  - `Docker Desktop is unable to start`
- 原因:
  - Docker Desktop 側の一時不調
- 対処:
  - Docker Desktop を再起動後、buildx を再実行して成功

## 4. 再実行用コマンド（今回使った実働コマンド）

### 4.1 SSO再ログイン

```bash
aws sso login --profile kokushiex-prod
aws sts get-caller-identity --profile kokushiex-prod
```

### 4.2 イメージ build/push（amd64固定）

```bash
docker buildx build \
  --platform linux/amd64 \
  -f Dockerfile.prod \
  -t 164249020242.dkr.ecr.ap-northeast-1.amazonaws.com/kokushiex-prod-app:latest \
  --push \
  .
```

### 4.3 ECS 再デプロイ

```bash
aws ecs update-service \
  --cluster kokushiex-prod-ecs-cluster \
  --service kokushiex-prod-web \
  --force-new-deployment \
  --profile kokushiex-prod \
  --region ap-northeast-1

aws ecs update-service \
  --cluster kokushiex-prod-ecs-cluster \
  --service kokushiex-prod-worker \
  --force-new-deployment \
  --profile kokushiex-prod \
  --region ap-northeast-1
```

### 4.4 稼働確認

```bash
aws ecs describe-services \
  --cluster kokushiex-prod-ecs-cluster \
  --services kokushiex-prod-web \
  --profile kokushiex-prod \
  --region ap-northeast-1 \
  --query 'services[0].{running:runningCount,desired:desiredCount,pending:pendingCount}'

aws elbv2 describe-target-health \
  --target-group-arn "$(aws elbv2 describe-target-groups --names kokushiex-prod-web-tg --profile kokushiex-prod --region ap-northeast-1 --query 'TargetGroups[0].TargetGroupArn' --output text)" \
  --profile kokushiex-prod \
  --region ap-northeast-1

curl -I https://app.kokushiex.com
```

## 5. 現時点で残っている作業（次フェーズ）

1. `terraform plan` でドリフト最終確認
2. 監視/通知（CloudWatch Alarm など）整備
3. CI/CD（GitHub Actions）導入
4. 運用手順（障害対応・ローテーション）整備
