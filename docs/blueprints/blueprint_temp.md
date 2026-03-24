# Blueprint: Task Expiry Visualization

## 1. Context
- **Goal**: タスク一覧画面で、期限が過ぎたタスクの背景を赤色にする。
- **Affected Files**: 
    - `app/lib/features/tasks/domain/task_model.dart`
    - `app/lib/features/tasks/presentation/task_item_widget.dart`

## 2. Implementation Steps
1. **Model Update**: `TaskModel` に `bool get isExpired` ゲッターを追加。`DateTime.now()` と `dueDate` を比較するロジックを実装せよ。
2. **UI Update**: `TaskItemWidget` の `Card` の `color` プロパティを修正。`task.isExpired` が true の場合は `Colors.red.withOpacity(0.1)` を適用せよ。

## 3. Constraints
- Flutter の推奨ルールに従い、`const` コンストラクタを維持すること。
- テーマカラー (`context.theme`) を使用し、直接的な色指定は避けること。

## 4. Verification
- [ ] 期限前のタスクは通常の背景色であること。
- [ ] 期限を1秒でも過ぎたタスクが即座に赤くなること。