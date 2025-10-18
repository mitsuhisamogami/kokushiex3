# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

## プロジェクト概要

kokushiEXは理学療法士国家試験の過去問練習用のRails 7.2アプリケーション（Ruby 3.3.8）です。

## 開発コマンド

### セットアップと起動

```bash
# 初期セットアップ
docker-compose up -d
docker-compose exec web rails db:create
docker-compose exec web rails db:migrate
docker-compose exec web rails db:seed_fu

# 開発サーバー起動（Rails + Tailwind CSSウォッチャー）
bin/dev

# またはDockerで
docker-compose up
```

### データベース

```bash
# データベース作成とマイグレーション
rails db:create
rails db:migrate

# seed-fuでシードデータ読み込み
rails db:seed_fu

# 特定のフィクスチャを読み込み（development/staging）
rails db:seed_fu FIXTURE_PATH=db/fixtures/development
rails db:seed_fu FIXTURE_PATH=db/fixtures/staging
```

### テスト

```bash
# 全テスト実行
bundle exec rspec

# 特定のテストファイルを実行
bundle exec rspec spec/models/user_spec.rb

# 特定の行番号のテストを実行
bundle exec rspec spec/models/user_spec.rb:42

# カバレッジ付きで実行
COVERAGE=true bundle exec rspec
```

### コード品質

```bash
# RuboCop実行
bundle exec rubocop

# RuboCopの自動修正
bundle exec rubocop -a

# ERBファイルのLint
bundle exec erblint --lint-all

# モデルアノテーション更新
bundle exec annotate --models
```

### アセットコンパイル

```bash
# TailwindでCSSをビルド
rails tailwindcss:build

# CSS変更を監視
rails tailwindcss:watch
```

## アーキテクチャ概要

### コアドメインモデル

アプリケーションは試験練習を中心とした以下の主要な関連性で構成されています：

1. **Test** → **TestSession** → **Question** → **Choice**
   - Testsは年度別の試験を表す
   - TestSessionsは試験をセッション（午前/午後）に分割
   - Questionsはquestion_number、content、オプションのimage_urlを持つ
   - Choicesはoption_numberとis_correctブール値を持つ

2. **User** → **Examination** → **UserResponse** → **Score**
   - Userは受験（attempt_date付きのExamination）を実施
   - UserResponsesは受験と選択肢の選択を紐付け
   - Scoresは`Score::ScoreCalculator`サービスオブジェクトで計算
   - 採点：問題1-20は「実地」（各3点）、21以降は「共通」（各1点）

3. **Question** ← **QuestionTag** → **Tag**
   - 問題分類のための多対多関係

4. **PassMark** → **Test**
   - 試験ごとのrequired_score、required_practical_score、total_scoreを格納

### 主要な設計パターン

1. **Decorator** (Draper): プレゼンテーションロジックの分離
   - `TestDecorator`、`QuestionDecorator`、`ScoreDecorator`
   - 表示フォーマットとビュー固有のロジックを処理

2. **Form Objects**: 複雑なフォーム処理
   - `MiniTestSearchForm`でカスタム試験フィルタリング

3. **Service Objects**: ビジネスロジックのカプセル化
   - `Score::ScoreCalculator` - スコア計算のためのネストクラス
   - `Examination.create_result!` - 試験結果作成のためのクラスメソッド
   - `UserResponse.bulk_create_responses` - ユーザー回答の一括挿入
   - `User.create_guest` - ランダムな認証情報でゲストユーザーを作成

### フロントエンドアーキテクチャ

- **Hotwire Stack**: Turbo + Stimulusでインタラクティブ性を実現
- **Tailwind CSS**: ユーティリティファーストのスタイリング
- **Import Maps**: JavaScriptのビルドステップ不要
- **Stimulus Controllers**:
  - `tab_controller`: タブナビゲーション
  - `results_display_controller`: 動的な結果表示

### データベーススキーマのハイライト

```ruby
# 主要テーブル (MySQL 8.4.3, utf8mb4)
tests: { year }
test_sessions: { test_id, session }
questions: { test_session_id, question_number, content, image_url }
choices: { question_id, content, option_number, is_correct }
examinations: { user_id, test_id, attempt_date }
user_responses: { examination_id, choice_id }
scores: { examination_id, common_score, practical_score, total_score }
pass_marks: { test_id, required_score, required_practical_score, total_score }
tags: { name }
question_tags: { question_id, tag_id }
users: { username, email, encrypted_password, confirmation_token, ... } # Deviseフィールド
```

## テスト戦略

- **Model Specs**: コアビジネスロジックとバリデーション
- **Request Specs**: コントローラーアクションとAPIの動作
- **Decorator Specs**: プレゼンテーションロジック
- **Form Specs**: フォームオブジェクトのバリデーションと動作
- **System Specs**: フルインテグレーションテスト（現在は最小限）

テストデータ生成にはFactoryBotファクトリを使用。ファクトリは`spec/factories/`で定義。

## 技術スタック

- **Ruby**: 3.3.8
- **Rails**: 7.2
- **Database**: MySQL 8.4.3（開発環境）、PostgreSQL（本番環境）
- **Authentication**: Deviseとconfirmableモジュール
- **Background Jobs**: SidekiqとRedis
- **Frontend**: Hotwire（Turbo + Stimulus）、Tailwind CSS、Import Maps
- **Testing**: RSpec、FactoryBot、Capybara、Selenium
- **Decorators**: Draper
- **Seeding**: seed-fu（`db/fixtures/development/`のフィクスチャ）
- **Linting**: RuboCop、ERB Lint
- **Development Tools**: Annotate、Better Errors、Letter Opener Web

## 重要な実装詳細

### ゲストユーザーシステム

ゲストユーザーは`User.create_guest`で作成されます：
- Email: `guest_#{random_hex}@example.com`
- Username: 'ゲストユーザー'
- ランダムな安全なパスワード
- `user.guest?`メソッドでメールパターンをチェックして識別

### 採点システム

`Score::ScoreCalculator`で実装：
- 問題1-20：実地問題（各3点）
- 問題21以降：共通問題（各1点）
- `Examination.create_result!`トランザクション内で計算
- `UserResponse.correct_responses`スコープを使用して正解数をカウント

### 試験作成フロー

```ruby
Examination.create_result!(
  user_id: user.id,
  test_id: test.id,
  attempt_date: Time.current,
  choice_ids: [1, 5, 9, ...] # ユーザーが選択した選択肢
)
```
このメソッドは：
1. Examinationレコードを作成
2. `UserResponse.bulk_create_responses`でUserResponseレコードを一括作成
3. `Score::ScoreCalculator`でScoreを計算・作成
4. choice IDが無効な場合は`Examination::InvalidChoiceError`を発生

## Docker開発

`docker-compose.yml`のサービス：
- **web**: Railsアプリ（`bin/dev`を実行 - Railsサーバー + Tailwindウォッチャー）
- **db**: MySQL 8.4.3（platform: linux/amd64でM1互換性を確保）
- **redis**: Sidekiq用のRedis
- **sidekiq**: バックグラウンドジョブプロセッサー

よく使うDockerコマンド：
```bash
# Railsコンソールにアクセス
docker-compose exec web rails console

# マイグレーション実行
docker-compose exec web rails db:migrate

# テスト実行
docker-compose exec web bundle exec rspec

# データベースにアクセス
docker-compose exec db mysql -u root -p
# パスワード: password (MYSQL_ROOT_PASSWORDより)
```

ボリュームマウント：
- `gem_data`: Gemバンドル（コンテナ再構築時も永続化）
- `mysql_data`: MySQLデータ
- `redis_data`: Redisデータ

## コードスタイルとパターン

- RuboCopルール（`.rubocop.yml`）に従う
- ビューロジックにはDraperデコレーターを使用（TestDecorator、QuestionDecorator、ScoreDecoratorなど）
- コントローラーは薄く保つ - ビジネスロジックはモデルまたはサービスオブジェクトに
- 複雑なフォームにはフォームオブジェクトを使用（例：`MiniTestSearchForm`）
- サービスオブジェクトはネストクラスまたはクラスメソッドとして実装（例：`Score::ScoreCalculator`）
- FactoryBotで包括的なRSpecテストを記述
- モデルにはスキーマアノテーションがある（`annotate` gem経由）- 更新を維持する
