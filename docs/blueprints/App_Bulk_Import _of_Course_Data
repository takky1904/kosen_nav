# Implementation Blueprint: App Bulk Import of Course Data

## Context
- **Goal**: サーバーから取得したシラバスJSONをパースし、ローカルDBの `Course` テーブルに一括で保存（Upsert）する。
- **Target Files**:
  - `lib/data/network/syllabus_api_client.dart` (新規APIクライアント)
  - `lib/data/repository/course_repository.dart`
  - `lib/domain/models/course.dart`

## Step-by-Step Instructions
1. **API Client Implementation**:
   - `SyllabusApiClient` を作成し、バックエンドの `GET /api/v1/syllabus` を叩いて Dart のオブジェクトリストに変換するメソッドを実装してください。
2. **Model Update**:
   - `Course` モデルに `teacher` (String), `credits` (int), `evaluations` (JSON/Map, 試験・課題等の割合を保持) のフィールドを追加してください。
   - `build_runner` を実行してください。
3. **Repository Bulk Upsert**:
   - `CourseRepository` に `syncSyllabusCourses(List<Course> courses)` を実装してください。
   - ループ処理またはDBのバッチ処理を用いて、取得した科目をローカルDBに保存します。既存の科目（名前が一致等）がある場合は上書き（Upsert）してください。
4. **Trigger Action**:
   - UI側に「シラバスから科目を同期する」ボタンを追加し、押下時に上記の一連の処理が走るように繋ぎ込んでください。

## Constraints
- **Offline Compatibility**: ネットワークエラー時は `SyllabusFetchException` を投げ、UI側で「オフラインのため取得できません」とトースト等で表示すること。
- **Data Integrity**: 評価割合などのJSON形式のデータは、SQLite等に保存する際、適切にStringにエンコード（パース）して保存すること。

## Verification
- [ ] 「シラバスから同期」ボタンを押した際、ローカルDBに科目データが追加されるか。
- [ ] 同期後、アプリを機内モード（オフライン）にしても科目一覧が表示されるか（Local DBから読み込まれているか）。