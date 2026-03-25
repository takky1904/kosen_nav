# Implementation Blueprint: Backend Syllabus Parsing Engine

## Context
- **Goal**: アプリからのリクエストを受け取り、対象のシラバスをスクレイピング（またはモックデータを返却）して、標準化されたJSONを返すAPIエンドポイントを作成する。
- **Target Files**:
  - `backend/routes/api/v1/syllabus/index.dart` (Dart Frog等の場合)
  - `backend/services/syllabus_scraper.dart`

## Step-by-Step Instructions
1. **Define API Schema**:
   - `GET /api/v1/syllabus` エンドポイントを作成してください。
   - クエリパラメータとして `?kosenName=xxx&grade=x&courseId=xxx` を受け取れるようにしてください。
2. **Implement Scraper Logic / Mock**:
   - （※最初はテスト用にモックデータで構いません）指定されたパラメータに基づいて、以下の構造を持つJSONリストを返す関数を作成してください。
   - レスポンス例:
     ```json
     [
       {
         "subjectName": "基礎数学A",
         "credits": 2,
         "teacher": "轟 龍一",
         "term": "前期",
         "evaluations": { "exam": 70, "assignment": 30, "other": 0 }
       }
     ]
     ```
3. **Implement Caching (Optional for V1)**:
   - データベースに同じ検索条件のデータが既にある場合はスクレイピングをスキップし、DBのキャッシュを返すロジックを組んでください。

## Constraints
- **Validation**: リクエストパラメータが不足している場合は `400 Bad Request` を返すこと。
- **Error Handling**: スクレイピング対象のサイトがダウンしている等の場合は、適切なエラーログを出力し `502 Bad Gateway` を返すこと。

## Verification
- [ ] ターミナルから `curl` または Postman で `GET /api/v1/syllabus?...` を叩き、期待するJSONが返ってくるか。
- [ ] 評価割合（`evaluations`）の合計が100%になるデータ構造になっているか。