# Implementation Blueprint: Cleanup Scraping & Migrate to Master Data

## Context
- **Goal**: 脆くて複雑な動的スクレイピング処理を完全に削除（一掃）し、堅牢な静的JSON（マスタデータ）方式へ移行するための基盤を整える。
- **Action**: `syllabus_scraper.dart` などのHTMLパース処理を削除する。ただし、プロフィール画面のドロップダウン（高専、学年、コース）を生成するために `nagano.json` を読み込むロジック（`kosen_rule_service.dart` 等）は残し、正常に機能するように整理する。

## Target Files
- **Backend**:
  - `backend/lib/src/services/syllabus_scraper.dart` (削除、または大幅なクリーンアップ)
  - `backend/lib/src/services/kosen_rule_service.dart` (JSON読み込みロジックの整理)
  - `backend/routes/api/v1/departments/index.dart` (プロフィール用API)
  - `backend/routes/api/v1/syllabus/index.dart` (シラバス用APIのスタブ化)
- **App**:
  - `lib/presentation/profile/profile_screen.dart` (変更なし、またはAPI連携の確認)

## Step-by-Step Instructions

### Step 1: Remove Scraping Logic (Backend)
1. `backend/lib/src/services/syllabus_scraper.dart` に存在する、`html` パッケージを使用したDOM解析、テーブル抽出、ディレイ（スリープ）などのWebスクレイピングに関する処理を**すべて削除**してください。
2. 今後このファイルは「マスタデータ（JSON）から科目リストを取得するサービス（例: `SyllabusDataService` 等）」として再利用するか、一旦空のクラス（スタブ）にしておいてください。
3. `pubspec.yaml` からスクレイピング専用のパッケージ（`html` など）があれば削除しても構いません。

### Step 2: Solidify JSON Parsing for Profile (Backend)
1. `backend/lib/src/services/kosen_rule_service.dart` を確認し、`backend/lib/src/config/kosen_rules/nagano.json` を読み込む処理が正しく動作するように整理してください。
2. このサービスは、アプリのプロフィール画面から「長野高専の3年」とリクエストされた際に、JSON内の該当学年の配列（`id` と `displayName`）を返すだけのシンプルな役割に徹するようにしてください。（※JSON内に残っている `scrapeTargets` フィールドは無視して読み飛ばして構いません）。

### Step 3: Clean up API Endpoints (Backend)
1. **Departments API (`routes/api/v1/departments/index.dart`)**: Step 2 の `kosen_rule_service.dart` を呼び出し、プロフィール画面のドロップダウン生成に必要なデータ（コース一覧等）を返す処理が正常に動くことを確認してください。
2. **Syllabus API (`routes/api/v1/syllabus/index.dart`)**: 現在スクレイパーを呼び出している部分を削除し、一旦「空のリスト `[]`」を返すか、「TODO: 今後JSONから静的科目データを返す」というコメントを残した仮の実装（スタブ）に置き換えてください。

### Step 4: Verification
- [ ] バックエンドからスクレイピング関連のコードが完全に消去されているか。
- [ ] アプリを起動し、プロフィール画面で「長野高専」「3年」を選択した際、JSONから取得されたコース一覧（情報エレクトロニクス系（情報コース）など）がドロップダウンに正しく表示されるか。