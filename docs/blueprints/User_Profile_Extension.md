# Implementation Blueprint: User Profile Extension & Setup UI

## Context
- **Goal**: ユーザーが所属（高専名、学年、コース）を選択・保存できるようにし、シラバス取得のキーとなるデータを保持する。
- **Target Files**:
  - `lib/domain/models/user.dart` (Userモデル)
  - `lib/data/local/` (ローカルDBのUserテーブル/DAO)
  - `lib/presentation/profile/` (プロフィール・設定画面UI)

## Step-by-Step Instructions
1. **Model Update**: 
   - `User` モデル（およびDBの `users` テーブル）に `kosenName` (String), `grade` (int), `courseId` (String) の3つのフィールドを追加してください。Nullableで構いません。
   - `build_runner` を実行し、FreezedやDrift等の自動生成コードを更新してください。
2. **Repository Update**: 
   - `UserRepository` に、ユーザーの所属情報を更新するメソッド `updateUserAffiliation(String kosenName, int grade, String courseId)` を実装してください。
3. **UI Implementation**: 
   - プロフィール設定画面（または初期セットアップ画面）に、3つのドロップダウン（`DropdownButton`等）を追加してください。
     - 高専名（例: 長野高専）
     - 学年（例: 1〜5）
     - コース（例: 情報工学科, 機械工学科など）
   - 保存ボタンを押した際に、2で作成したメソッドを呼び出してローカルDBに保存し、UIの状態を更新してください。

## Constraints
- **Architecture**: 既存のMVVM / Riverpod（またはプロジェクトの標準状態管理）のルールに従うこと。
- **Local First**: サーバーへの送信はここでは考えず、まずはローカルDB（または `SharedPreferences` / `Flutter Secure Storage`）に確実に永続化すること。

## Verification
- [ ] 設定画面で所属を選択し、保存ボタンを押すとエラーなく完了するか。
- [ ] アプリを再起動しても、設定画面で選択した所属情報が復元されて表示されるか。