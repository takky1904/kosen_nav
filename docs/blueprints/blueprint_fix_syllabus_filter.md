# Implementation Blueprint: Fix Syllabus Scraper Filtering

## Context
- **Issue**: 現在、シラバスの自動取得機能ですべての科目が取得されてしまっている。ユーザーのプロフィール（高専、学年、コースID）に基づき、必要な科目のみをフィルタリングして取得するように修正したい。
- **Core Concept**: `nagano.json` に定義された `scrapeTargets` 配列を利用し、スクレイパーが特定の科目区分（テーブル）のみを抽出するようにロジックを修正する。

## Target Files
- **App**: `app/lib/data/network/syllabus_api_client.dart`
- **Backend**:
  - `backend/lib/src/services/course_data_service.dart`
  - `backend/lib/src/services/syllabus_scraper.dart`
  - `backend/routes/api/v1/syllabus/index.dart`

## Step-by-Step Instructions

### Step 1: App Side - Send Profile Data to API
1. `syllabus_api_client.dart` を修正し、シラバス取得のAPIリクエスト (`GET /api/v1/syllabus`) を送る際に、現在ログインしているユーザーの `kosenName` (または `kosenId`), `grade`, `courseId` をクエリパラメータとして確実に付与するようにしてください。
   例: `/api/v1/syllabus?kosenId=nagano&grade=3&courseId=info_elec_info`

### Step 2: Backend Side - Load `scrapeTargets` (`course_data_service.dart`)
1. `course_data_service.dart` に、リクエストされた `kosenId` に対応するJSONファイル（例: `nagano.json`）を読み込む処理を実装してください。
2. JSONの `grades` オブジェクトから該当する学年（例: `"3"`）の配列を取得し、その中からリクエストされた `courseId`（例: `"info_elec_info"`）に一致するオブジェクトを検索してください。
3. 一致したオブジェクトの `scrapeTargets` 配列（例: `["一般科目：全系共通", "専門科目：全系共通", ...]`) を抽出して返すメソッドを実装してください。

### Step 3: Backend Side - Filter Scraper by Targets (`syllabus_scraper.dart`)
1. `syllabus_scraper.dart` のスクレイピング処理を修正します。引数として Step 2 で取得した `scrapeTargets` のリスト（`List<String>`）を受け取るようにしてください。
2. HTMLをパースして科目テーブルを抽出する際、対象のテーブル（またはその見出し要素）のテキストが `scrapeTargets` の文字列と一致する、あるいは部分一致するかを判定する `if` 文を追加してください。
3. **条件に一致したセクション（科目区分）の科目のみ**をリストに追加して返すように抽出ロジックを制限してください。

## Verification
- [ ] アプリからリクエストを送った際、バックエンドで正しく `scrapeTargets` が解決されているか（サーバーのログで確認）。
- [ ] プロフィールで指定したコースに関連する科目（例えば「情報エレクトロニクス系」の専門科目）のみがアプリ側に返ってきているか。