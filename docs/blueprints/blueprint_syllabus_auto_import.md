# Implementation Blueprint: Automated Syllabus Sync

## Context
- **Goal**: ユーザーの所属情報（高専、学年、学科）に基づいて、バックエンドでシラバスをスクレイピングし、アプリのローカルDBに履修科目、単位数、担当教員、そして成績シミュレーションに必要な「テスト比率」を自動保存する。
- **Core Concept**: 既存の「手動追加UI」は残しつつ、プロフィール登録後の「初期セットアップ」フローとしてシラバス自動同期ボタンを追加する。
- **Target Files**:
  - **Backend**:
    - `backend/lib/src/config/kosen_rules/nagano.json` (高専別JSON定義)
    - `backend/lib/src/services/syllabus_scraper.dart` (スクレイパー実装)
    - `backend/routes/api/v1/syllabus/index.dart` (APIエンドポイント)
  - **App (Frontend)**:
    - `lib/data/network/syllabus_api_client.dart` (新規作成)
    - `lib/domain/models/course.dart` (または関連する成績モデル)
    - `lib/presentation/profile/profile_screen.dart` (UI改修)
    - `lib/presentation/subjects/` (履修科目リストUI)

## Step-by-Step Instructions

### Step 1: Backend: Implement Multi-Level Scraper Logic (`syllabus_scraper.dart`)
1. 以前作成した全国対応の4階層クローラー設計と長野高専のJSON定義 (`nagano.json`) を読み込んでください。
2. 引数の所属情報に基づき、対象高専のシラバスサイトのトップから階層を辿り、該当学科の科目一覧テーブルにアクセスしてください。
3. 科目一覧テーブルから、以下の基本データを抽出するロジックを実装してください：
   - `subjectName`: 授業科目（例: `ZUKUDASEゼミ`, `基礎国語 I` 等）
   - `credits`: 単位数（例: `1`, `2`）
   - `teacher`: 担当教員（例: `久保田 和男` 等）
   - `detailUrl`: 科目詳細ページへのURL（絶対URLに変換）
4. **【重要】** 各科目の `detailUrl` にスリープ（Delay）を挟みながらアクセスし、詳細ページの「評価割合」テーブルから「試験」の合計値（例: `70`）を抽出してください。
5. 抽出したデータを、以下の標準化されたJSON形式（List形式）に変換して返す関数を完成させてください。
   (レスポンス例)
   [
     {
       "subjectName": "基礎数学A",
       "credits": 2,
       "teacher": "轟 龍一",
       "examRatio": 70 
     }
   ]

### Step 2: Backend: Implement Syllabus API Endpoint (`routes/api/v1/syllabus/index.dart`)
1. `GET /api/v1/syllabus` を作成し、`?kosenName=xxx&grade=x&courseId=xxx` クエリを受け取るようにしてください。
2. Step 1 で実装した `SyllabusScraper` サービスを呼び出してください。
3. 抽出されたJSONリストをレスポンスとして返却してください。

### Step 3: App: Extend Model & Local DB
1. `Course` モデル（または関連する成績モデル）に、`credits` (int), `teacher` (String), `examRatio` (int, default: null) フィールドを追加してください。
2. `sqflite` のマイグレーションスクリプトを作成し、ローカルDBのテーブルにこれらのカラムを追加してください。

### Step 4: App: Implement SyllabusApiClient & Auto-Import Flow
1. `SyllabusApiClient` を作成し、バックエンドの `GET /api/v1/syllabus` を叩いてデータを取得する処理を実装してください。
2. `profile_screen.dart` を改修し、所属情報の登録が完了した後に、「シラバスから科目を自動同期する」ボタンを表示してください。
3. ボタン押下時に `SyllabusApiClient` を介してデータを取得し、取得した科目をローカルDBに一括保存（Upsert = 既存科目は上書き、新規科目は追加）するロジックを実装してください。

### Step 5: App: Update Grade Simulation & UI
1. 自動同期された科目が、既存の「履修科目」画面のリストに画像と同じスタイルで表示されるように、データソース（RiverpodのProvider等）を繋ぎ込んでください。
2. 成績計算ロジックを改修し、自動取得された `examRatio`（テスト比率）が null でない場合は、手動設定値ではなくその比率を用いて成績を算出（`(テスト点 × (examRatio / 100)) + (平常点 × ((100-examRatio) / 100))`）するように修正してください。

## Constraints
- **Preserve Manual Addition**: 既存の「＋ 科目追加」ボタンと手動追加機能は削除しないこと。自動取得に失敗した場合のフォールバックとして維持する。
- **Null Safety**: 手動登録された科目の `examRatio` は null になる可能性があるため、計算時に安全にNullチェックを行い、フォールバック挙動（例: 手動設定値を優先）を実装すること。
- **Database Upsert**: 自動同期ボタンを複数回押した場合でも、科目が重複して登録されないよう、科目名等をキーにして Upsert ロジックを実装すること。

## Verification
- [ ] 所属を選択した後、同期ボタンを押すと、画像通りの科目名、単位数、担当教員がローカルDBに保存されるか。
- [ ] 保存された科目が「履修科目」画面のリストに正しく表示されるか。
- [ ] テスト点数を入力した際、詳細ページから取得したテスト比率（70%）に基づいた計算結果が、UIの評価点にリアルタイム反映されるか。