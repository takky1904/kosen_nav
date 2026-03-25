# Implementation Blueprint: Integrating Syllabus Data with Existing Grade Simulation

## Context
- **Goal**: 既に実装済みの「成績管理・シミュレーション機能」を拡張し、シラバスから自動取得した評価割合（重み付け）を計算ロジックに組み込む。ユーザーは「テストの点数」を入力するだけで済むようにする。
- **Target Files**:
  - `lib/domain/models/course.dart` (または関連する成績モデル)
  - `lib/presentation/course_detail/` (既存の成績入力・シミュレーションUI)
  - `lib/application/` (既存の成績計算ロジック・ViewModel)

## Step-by-Step Instructions
1. **Analyze Existing Implementation**:
   - まず、現在の「手動入力による成績管理・シミュレーション」のコード（UIと計算ロジック）を読み込み、どのように点数と割合（重み付け）を計算しているか把握してください。
2. **Model & State Binding**:
   - `Course` モデルに保存された `evaluations`（シラバスから取得した試験70%、課題30%などの割合データ）を、既存のシミュレーションロジックの「割合（Weight）の初期値」としてバインドしてください。
3. **UI Adjustment (Read-Only Mode for Weights)**:
   - 既存の成績入力UIを改修します。
   - 対象の科目が「シラバスから自動取得した科目（`evaluations`が存在する）」である場合、評価割合（%）を入力するフィールドを **Read-Only（編集不可）** にするか、「シラバス同期済」というバッジを表示して固定値として扱ってください。
   - ユーザーが入力する「実際の獲得点数」のフィールドはそのまま編集可能にしておきます。
4. **Backward Compatibility (手動入力との共存)**:
   - 対象の科目が「手動で追加した科目（`evaluations`がnullや空）」である場合は、今まで通りユーザーが評価割合（%）も自由に入力・編集できるように、既存の挙動を完全に維持してください。

## Constraints
- **Preserve Existing Logic**: 既存のシミュレーションの計算式やUIコンポーネントを破壊しないでください。既存のクラスを拡張（または分岐を追加）する形で実装すること。
- **Null Safety**: シラバスデータがない（手動登録された）科目がクラッシュしないよう、安全なフォールバック（Nullチェック）を必ず実装すること。

## Verification
- [ ] シラバスから取得した科目を開いた際、評価割合（例: 試験70%）が自動でセットされており、ユーザーが変更できない（または固定されている）か。
- [ ] その科目に点数を入力した際、既存のプログレスバーやシミュレーション結果が正しく動くか。
- [ ] 手動で新規作成した科目を開いた際は、今まで通り割合（%）も点数も両方自由に入力できるか。