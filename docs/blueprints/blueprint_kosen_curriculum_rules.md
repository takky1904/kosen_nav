# Implementation Blueprint: Config-Driven Curriculum Rules

## Context
- **Goal**: 各高専で異なる「学年ごとの専攻（コース）の分岐ルール」と、「シラバスサイト上のカテゴリ名（共通科目など）」の紐付けを管理するルールエンジンを実装する。
- **Target Files**:
  - `backend/lib/src/config/kosen_rules/nagano.json` (新規作成: ルール定義)
  - `backend/routes/api/v1/departments/index.dart` (専攻一覧APIの改修)
  - `backend/services/syllabus_scraper.dart` (スクレイパーの改修)

## Step-by-Step Instructions

### Step 1: KOSEN Rule Config の作成
1. `backend/lib/src/config/kosen_rules/` ディレクトリを作成し、長野高専用のJSONファイル（例: `nagano.json`）を作成してください。
2. JSONには、学年（1〜5）ごとに、UIで表示するコース名（`displayName`）と、シラバススクレイピング時に抽出対象とするページリンクのキーワード（`scrapeTargets`: 例 `["全系共通", "情報エレクトロニクス系"]`）の配列を定義してください。

### Step 2: Departments API の動的化
1. `GET /api/v1/departments` エンドポイントを改修し、クエリパラメータとして `?kosenName=xxx&grade=x` を必須で受け取るようにしてください。
2. リクエストされた `kosenName` に対応する JSON設定ファイルを読み込み、指定された `grade` に紐づく `displayName` のリストをアプリ側に返却してください。
   - ※これによって、1年生なら「工学科」のみ、3年生なら「情報コース」などが動的にUIに表示されるようになります。

### Step 3: Scraper Logic のアグリゲーション対応
1. `GET /api/v1/syllabus` が呼び出された際、対象のJSON設定ファイルを読み込み、ユーザーの `courseId` (displayName) に紐づく `scrapeTargets` の配列を取得してください。
2. シラバスの学科一覧ページの中から、`scrapeTargets` に部分一致するリンクを **すべて** 抽出してください。
3. 抽出した複数のリンクのそれぞれに対して科目一覧と評価割合を取得し、1つのリストに結合（重複排除）して JSON で返却してください。

## Constraints
- **Scalability**: 将来的に他の高専のルールを追加しやすいよう、JSONファイルをパースして管理する `KosenRuleService` クラスのようなものを中継させること。
- **Fallback**: 設定JSONが存在しない高専がリクエストされた場合は、従来の「シラバスサイトから直接リンク名をスクレイピングして返す」フォールバック処理を残しておくこと（全国展開への備え）。

## Verification
- [ ] 1年生を選択したときはコースが分岐せず、2年生以上を選択したときは正しい系やコースがレスポンスされるか。
- [ ] シラバス取得時、JSONの `scrapeTargets` に定義した複数ページ（共通科目＋専門科目）の科目が統合されて返ってくるか。