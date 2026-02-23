# AWS Identity Center 初期設定メモ（Terraform実行基盤）

このドキュメントは、`kokushiEX3` のインフラ構築前に実施した
Identity Center / Organizations の初期設定を再現するための記録です。

最終更新: 2026-02-22

## 1. 方針

- 管理アカウントで日常運用しない
- IAMユーザーを常用しない（Identity Center を利用）
- Terraform はメンバーアカウントに対して実行する

## 2. 今回作成・確定した値

- 管理アカウントID: `116981795908`
- メンバーアカウントID（作業対象）: `164249020242`
- AWSリージョン: `ap-northeast-1`
- Permission Set 名: `TerraformAdminAccess`
- CLI SSO Session 名: `kokushiex-sso`
- CLI Profile 名: `kokushiex-prod`
- Start URL: `https://d-9567afc083.awsapps.com/start`

## 3. 実施内容

1. IAM Identity Center を有効化
2. AWS Organizations でメンバーアカウントを作成（`kokushiex-prod`）
3. Identity Center ユーザー `mogami` を作成
4. Permission Set `TerraformAdminAccess` を作成
5. `kokushiex-prod` アカウントへ `mogami` + `TerraformAdminAccess` を割り当て
6. ローカルで `aws configure sso` を実行
7. `aws sso login --profile kokushiex-prod` でログイン成功
8. `aws sts get-caller-identity --profile kokushiex-prod` で確認

確認済みARN:
- `arn:aws:sts::164249020242:assumed-role/AWSReservedSSO_TerraformAdminAccess_d0eb1f1c5af40f22/mogami`

## 4. 以降の標準コマンド

```bash
aws sso login --profile kokushiex-prod
aws sts get-caller-identity --profile kokushiex-prod
```

Terraform 実行時:

```bash
cd infra/terraform
AWS_PROFILE=kokushiex-prod terraform init
AWS_PROFILE=kokushiex-prod terraform plan
AWS_PROFILE=kokushiex-prod terraform apply
```

## 5. `aws configure sso` 推奨入力

- SSO session name: `kokushiex-sso`
- SSO start URL: `https://d-9567afc083.awsapps.com/start`
- SSO region: `ap-northeast-1`
- SSO registration scopes: `sso:account:access`
- Account: `164249020242`
- Role/Permission set: `TerraformAdminAccess`
- CLI default region: `ap-northeast-1`
- CLI output: `json`
- CLI profile name: `kokushiex-prod`

## 6. セキュリティメモ

- 現在の Permission Set は初期構築優先で強め（`AdministratorAccess`）
- インフラ構築後に Terraform 用最小権限へ段階的に縮小する
- MFA を必須化して運用する

