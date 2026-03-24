# Implementation Blueprint: Offline-First Synchronization

## Context
- **Goal**: タスク（課題）および履修科目データをローカルデータベース（SQLite/Drift等）に保存し、オフライン環境でもアプリを完全に使用可能にする。ネットワーク接続が回復したタイミングで、バックグラウンドでリモートサーバー（バックエンド）へデータを同期（バックアップ）する。
- **Target Files**:
  - `lib/data/local/` (Local DB Schema / DAOs)
  - `lib/data/repository/` (TaskRepository, CourseRepository)
  - `lib/data/sync/` (新規作成: SyncService)
  - `lib/core/network/` (新規作成: ConnectivityListener)
- **Architecture**: Local DB を **Single Source of Truth (信頼できる唯一の情報源)** とし、UI は常にローカル DB のみを監視（Stream）する。



## Step-by-Step Instructions

### Step 1: Update Local Database Schema
ローカルDBのテーブル（`Task` および `Course`）に、同期状態を管理するためのカラムを追加してください。
1. 以下のカラムを追加:
   - `remote_id` (String, nullable): サーバー側のID。未同期の新規作成データはnullになる。
   - `sync_status` (String): 同期状態。`synced` (同期済), `pending_insert` (新規追加・未送信), `pending_update` (更新済・未送信), `pending_delete` (削除済・未送信) のいずれか。
   - `updated_at` (DateTime): 競合解決のためのローカル更新日時。
2. スキーマ変更に伴うマイグレーション処理を記述、またはコードジェネレーター（`build_runner`）を実行してください。

### Step 2: Refactor Repositories to be "Local-First"
リポジトリ層（`TaskRepository` 等）のメソッドを、APIを直接叩くのではなく「ローカルDBを操作する」処理に書き換えてください。
1. `createTask`: ローカルDBに `sync_status = 'pending_insert'` として保存する。
2. `updateTask`: ローカルDBのデータを更新し、`sync_status = 'pending_update'` に変更する。
3. `deleteTask`: 物理削除せず、`sync_status = 'pending_delete'` として論理削除（UIからは非表示にする）する。
4. `getTasksStream`: ローカルDBから `sync_status != 'pending_delete'` のタスクを Stream で返す。

### Step 3: Implement the Sync Service
ローカルDBとリモートサーバー間のデータ同期を担う `SyncService` を作成してください。
1. `pushLocalChanges()` メソッドを作成:
   - ローカルDBから `sync_status` が `pending_*` のレコードを取得。
   - `pending_insert` なら POST リクエスト、`pending_update` なら PUT/PATCH リクエスト、`pending_delete` なら DELETE リクエストをサーバーに送信。
   - APIリクエストが成功したら、ローカルDBのレコードの `sync_status` を `synced` に更新（または論理削除レコードを物理削除）する。
2. `fetchRemoteChanges()` メソッドを作成:
   - サーバーから最新データを取得し、ローカルDBを更新（Upsert）する。その際、ローカルで編集中のデータ（`pending_*`）は上書きしないよう除外する。

### Step 4: Implement Connectivity Listener
ネットワークの復帰を検知して同期をトリガーする仕組みを作ります。
1. `connectivity_plus` パッケージを使用し、ネットワーク状態の変更を監視するリスナーを作成。
2. 状態が `none`（オフライン）から `wifi` または `mobile` に変化したことを検知したら、`SyncService.pushLocalChanges()` および `fetchRemoteChanges()` を実行する。
3. 同期処理中は、重複実行を防ぐための排他制御（isSyncing フラグなど）を設ける。

## Constraints
- **Libraries**:
  - Local DB: プロジェクトで採用中のもの (`drift`, `sqflite`, `isar` 等)。
  - Network Detection: `connectivity_plus` を使用。
- **Architecture**: UIレイヤー（ViewModel / Controller）から直接 API を呼び出すことは**厳禁**。UI はローカルDBの変更を検知して再描画されるのみ（リアクティブプログラミング）。
- **Error Handling**: 同期中のネットワークエラーは握りつぶし、次回オンライン時に再試行されるようローカルの `sync_status` を維持すること。

## Verification
- [ ] 機内モード（オフライン）状態でタスクを新規作成・編集できるか。
- [ ] オフラインで作成したタスクが、UI上に即座に表示されるか。
- [ ] アプリを一度タスクキルして再起動しても、オフライン作成したデータが残っているか。
- [ ] 機内モードを解除（オンライン化）した際、バックグラウンドでAPIにリクエストが飛び、サーバー側にデータが保存されるか。
- [ ] サーバー保存成功後、ローカルDBの対象レコードの `sync_status` が `synced` に変更されているか。