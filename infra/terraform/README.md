# Terraform for AWS Minimum Production

このディレクトリは `kokushiEX3` の AWS 本番インフラを Terraform で管理するための定義です。

対象構成:
- ECS on EC2（`web=1`, `worker=1`）
- RDS PostgreSQL
- ElastiCache Redis
- ALB（origin）
- Cloudflare DNS（独自ドメイン）
- AWS WAF（ALB関連付け）
- ECR

## 使い方

1. `terraform.tfvars.example` をコピー
2. 値を埋めて `terraform.tfvars` を作成
3. 実行

```bash
cd infra/terraform
terraform init
terraform plan
terraform apply
```

## 注意点

- 本番用 state は S3 backend + DynamoDB lock への変更を推奨（`providers.tf` の backend を有効化）
- まずは最小構成で固定スケール（ASG min/max/desired = 1）
- `app_image` は ECR に push 済みイメージ URI を指定
- Secret 値は `terraform.tfvars` 直書きではなく、CI から `TF_VAR_...` 注入を推奨
- `rails_master_key` も Terraform 変数で渡し、ECS に `RAILS_MASTER_KEY` として注入する
- Terraform apply 後、Cloudflare DNS で `app` の CNAME を `alb_dns_name` に向ける
- `alb_certificate_arn` を指定すると ALB に HTTPS(443) リスナーを作成し、HTTP は 443 へリダイレクト

## デプロイ後の手順

- ECS service update（新しいイメージへ切替）
- DB migrate
- 必要なら seed 実行
