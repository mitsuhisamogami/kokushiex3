# Repository Guidelines

## プロジェクト構成とモジュール配置
- Rails の主要コードは `app/` 以下にまとまり、`app/models`・`app/controllers`・`app/views` がドメインとフローを対応付けます。Hotwire Stimulus は `app/javascript/controllers`、フォームオブジェクトは `app/forms`、認可は `app/policies` に配置します。
- 非同期系は `app/jobs`、メールは `app/mailers`、Tailwind 由来のスタイルは `app/assets/stylesheets` と `app/javascript/stylesheets` に整理されています。デコレーター（`app/decorators`）でビュー専用ロジックを切り出します。
- テストは `spec/` に集約され、`models`・`requests`・`system`・`support` が役割別に分離されています。シードと seed-fu 用フィクスチャは `db/fixtures` に置き、Docker 設定 (`Dockerfile`、`docker-compose.yml`) や `Procfile.dev` はルートに配置されています。

## ビルド・テスト・開発コマンド
- `docker-compose up -d`：MySQL・Redis・Rails コンテナをバックグラウンド起動します。
- `docker-compose exec web bin/dev`：Rails サーバーと Tailwind ウォッチャーをまとめて起動し、開発ループを回します。
- `docker-compose exec web bundle exec rspec`：RSpec を全件実行します。`spec/models/user_spec.rb` のようにパスを付けると対象を絞れます。
- `docker-compose exec web bundle exec rubocop` および `docker-compose exec web bundle exec erblint --lint-all`：Ruby と ERB の静的解析を走らせ、スタイル違反を検出します。
- `docker-compose exec web bundle exec annotate --models`：モデルのスキーマアノテーションを最新化します。DB 変更後に実行してください。
- `docker-compose exec web rails console` で Rails コンソールへ、`docker-compose exec web rails tailwindcss:build` で単発ビルドが可能です。

## アーキテクチャ概要
- コアドメインは「試験(Test) → セッション(TestSession) → 問題(Question) → 選択肢(Choice)」と「ユーザー(User) → 受験(Examination) → 回答(UserResponse) → スコア(Score)」の二軸で構成され、`Score::ScoreCalculator` が採点ロジックを担います。
- タグ分類は Question と Tag の多対多 (`QuestionTag`) で実装され、`PassMark` が合格基準を管理します。ゲスト受験は `User.create_guest` で乱数クレデンシャルを生成し、`UserResponse.bulk_create_responses` で一括挿入します。
- プレゼンテーションは Draper デコレーター (`TestDecorator` など) と Hotwire (Turbo + Stimulus) で組み立て、Import Maps でビルドレスに管理しています。Tailwind が UI の基盤です。

## コーディングスタイルと命名規則
- Ruby はスペース 2 つのインデント、メソッドは `snake_case`、クラス・モジュールは `CamelCase` で統一します。ビジネスロジックはサービスやフォームオブジェクトに寄せ、コントローラを薄く保ちます。
- JavaScript は Stimulus の命名 (`*_controller.js`) とディレクトリ構造に従います。スタイルは Tailwind のユーティリティクラスを優先し、共通化が必要な場合のみ CSS を追加します。
- コミット前に RuboCop を必ず実行し、`rubocop -a` での自動修正は差分を確認したうえで使用します。ERB は `app/views/shared` などにパーシャル化して再利用性を高めます。
- `annotate` で付与されるスキーマコメントを更新し忘れないよう、マイグレーション後に再生成してください。

## テストガイドライン
- RSpec と FactoryBot を基本とし、ファイル名は `*_spec.rb` で対象クラスと同じ階層に配置します（例：`app/models/user.rb` → `spec/models/user_spec.rb`）。
- システムテストは Capybara を用い、Turbo で非同期挙動が必要なケースのみ `:js` タグを付けます。
- ローカルでカバレッジを確認する場合は `COVERAGE=true` を付けて RSpec を実行し、生成される `coverage/` レポートで分岐の取りこぼしを確認します。

## コミットおよびプルリクエスト方針
- Git 履歴に倣い、コミットの冒頭には `[add]`・`[fix]`・`[chore]` のような角括弧付きラベルと簡潔な命令形サマリを付けます。
- 機能追加とリファクタリングを同一コミットに混在させず、関連する変更を 1 セットにまとめます。Issue があれば本文で参照します。
- プルリクエストには目的概要、実行したテストや取得したスクリーンショット、追跡すべき残課題を記載します。マイグレーションやシードを変更した場合は手順も明記してください。

## セキュリティと設定の注意点
- 機密情報は環境変数で管理し、`README.md` に設定手順を追記しつつ秘密鍵や資格情報はコミットしないでください。Docker Compose で起動する Redis や MySQL のパスワードも平文で共有しないよう注意します。
- CSP (`config/initializers/content_security_policy.rb`) は本番で強制、開発で report-only です。変更時は nonce 付与や frame-ancestors の影響範囲を確認してください。
- 認証は Devise、認可は Pundit を使用し、`ExaminationPolicy` や `ScorePolicy` の条件を破らないようテストで担保します。Sidekiq 管理画面は `SidekiqAdminMiddleware` で管理者のみ許可されるため、ルーティング追加時のアクセス制御を忘れないでください。
- Rack::Attack（`config/initializers/rack_attack.rb`）のレート制限は登録・ログイン・ゲスト作成・試験提出それぞれに設定があります。閾値変更時は Redis DB1 をクリアして検証し、必要なら README/PR で周知してください。
