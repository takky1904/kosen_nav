# Implementation Blueprint: Profile Screen with Master Data (JSON)

## Context
- **Goal**: アプリのプロフィール画面における「高専」「学年」「コース」の選択ドロップダウンを、スクレイピングではなくバックエンドのJSONファイル群（マスタデータ）から動的に生成する構成に作り直す。
- **Core Concept**: `backend/lib/src/config/kosen_rules/` にある複数のJSONファイル（`nagano.json`, `tokyo.json`, `akashi.json`）を読み込み、API経由でアプリに提供する。

## Target Files
- **Backend**:
  - `backend/lib/src/services/kosen_rule_service.dart` (JSONを読み込むロジック)
  - `backend/routes/api/v1/schools/index.dart` (高専一覧を返すAPI)
  - `backend/routes/api/v1/departments/index.dart` (学科/コース一覧を返すAPI)
- **App**:
  - `lib/presentation/profile/profile_screen.dart` (UIのドロップダウン連動)
  - `lib/presentation/profile/profile_controller.dart` (状態管理)

## Step-by-Step Instructions

### Step 1: Backend - Implement KosenRuleService
1. `kosen_rule_service.dart` に、`config/kosen_rules/` ディレクトリ内のすべての `.json` ファイルを読み込み、メモリ上にキャッシュする処理（初期化処理）を実装してください。
2. 以下の2つのメソッドを提供してください：
   - `List<Map<String, dynamic>> getAvailableSchools()`: 読み込んだすべてのJSONから `kosenId` と `kosenName` のペアのリストを返す。
   - `List<Map<String, dynamic>> getDepartments(String kosenId, String grade)`: 指定された高専・学年に紐づく `id` と `displayName` のリストを返す。

### Step 2: Backend - Update API Endpoints
1. `GET /api/v1/schools` エンドポイントを実装し、`getAvailableSchools()` の結果をJSONで返却するようにしてください。
2. `GET /api/v1/departments` エンドポイントを実装し、クエリパラメータ `?kosenId=xxx&grade=x` を受け取り、`getDepartments()` の結果をJSONで返却するようにしてください。

### Step 3: App - Connect Profile Screen
1. `profile_screen.dart` と `profile_controller.dart` を改修し、画面表示時に `GET /api/v1/schools` を叩いて「高専選択ドロップダウン」の選択肢を生成してください（長野高専、東京高専、明石高専が表示されること）。
2. 「高専」と「学年（1〜5）」が選択されたら、動的に `GET /api/v1/departments?kosenId=xxx&grade=x` を叩き、その結果で「コース選択ドロップダウン」を生成してください。
3. ユーザーが全てを選択して「保存」を押した際、ローカルDB（Userモデル）には表示名ではなく `kosenId` とコースの `id` が保存されることを確認してください。

## Constraints
- バックエンドでのJSONファイルの読み込みは、リクエストのたびにファイルをパースするのではなく、サーバー起動時（または初回リクエスト時）にパースして変数に保持しておくことで高速化を図ること。

## Verification
- [ ] アプリを起動し、プロフィール画面で高専が3つ（長野、東京、明石）選べるか。
- [ ] 東京高専を選ぶと「情報工学科」などが表示され、長野高専の3年を選ぶと「情報エレクトロニクス系（情報コース）」が表示されるといったように、ドロップダウンが連動して変化するか。