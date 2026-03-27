# Implementation Blueprint: Master Data Syllabus API Foundation

## Context
- **Goal**: ユーザーのプロフィール（kosenId, grade, courseId）に基づいて、静的なJSONマスタデータから適切な履修科目リストを返すバックエンドAPIの土台を構築する。
- **Core Concept**: 複雑なスクレイピングを廃止し、`backend/lib/src/config/syllabus_data/` に配置された各高専のJSONファイルからデータを読み込み、条件に合致する科目リストを抽出して返す。

## Target Files
- **Backend**:
  - `backend/lib/src/services/syllabus_data_service.dart` (新規作成: JSONを読み込んで検索するサービス)
  - `backend/routes/api/v1/syllabus/index.dart` (APIエンドポイントの改修)
- **App**:
  - `lib/data/network/syllabus_api_client.dart` (改修: APIを叩くクライアント)

## Step-by-Step Instructions

### Step 1: Backend - Implement SyllabusDataService
1. `backend/lib/src/services/syllabus_data_service.dart` を新規作成してください。
2. `config/syllabus_data/` ディレクトリ内のJSONファイル（`nagano.json`, `tokyo.json` 等）を読み込むロジックを実装してください（サーバー起動時または初回アクセス時にメモリにキャッシュすることが望ましいです）。
3. 以下のメソッドを実装してください：
   - `List<dynamic> getSubjects(String kosenId, String grade, String courseId)`
   - このメソッドは、指定された `kosenId` のJSONデータを検索し、`grade` と `courseId` が完全に一致するブロックを探し、その中の `subjects` 配列を返します。見つからない場合は空のリスト `[]` を返します。

### Step 2: Backend - Update Syllabus API Endpoint
1. `backend/routes/api/v1/syllabus/index.dart` を改修し、`GET /api/v1/syllabus` リクエストを受け取れるようにしてください。
2. クエリパラメータから `kosenId`, `grade`, `courseId` を取得し、必須パラメータが欠けている場合は `400 Bad Request` を返してください。
3. `SyllabusDataService.getSubjects(...)` を呼び出し、取得した科目リストをJSONとして返却（`200 OK`）してください。

### Step 3: App - Connect and Verify (Console Log)
1. `lib/data/network/syllabus_api_client.dart` を実装し、上記のAPIを叩いてデータを取得するメソッドを作成してください。
2. アプリのどこか（例えばプロフィール保存完了時、または検証用の一時ボタン）でこのクライアントを呼び出し、プロフィールで設定した情報（長野/情報、長野/機械、東京/情報）に応じたJSONが正しくコンソール（print文）に出力されるか確認できる簡単なテストコードを仕込んでください。

## Verification
- [ ] バックエンドを起動し、ブラウザ等で `http://localhost:8080/api/v1/syllabus?kosenId=nagano&grade=3&courseId=info_elec_info` にアクセスした際、「ZUKUDASEゼミ」を含むJSONが返ってくるか。
- [ ] `courseId=mech` に変えた際、「機械設計法」を含むJSONが返ってくるか。
- [ ] `kosenId=tokyo&courseId=info` に変えた際、「アルゴリズムとデータ構造」を含むJSONが返ってくるか。