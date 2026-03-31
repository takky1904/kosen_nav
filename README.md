# Kosenar

Kosenar(コセナール) は、高専生向けのタスク・成績管理アプリです。
日々の課題管理と成績の見える化を一つのアプリで行えるように設計しています。
＊”Kosenar”は、KOSEN + Dominar（スペイン：熟達する，マスターする；意のままに操る）という造語です。

## できること

- タスクの登録・編集・削除
- タスクの進捗管理（TODO / DOING / DONE）
- ガントチャートによるスケジュール確認
- 履修科目の登録と成績入力
- テスト平均・加重平均・最終成績の自動計算
- 要注意科目の可視化と学習アドバイス表示
- Teams ログインとプロフィール連携

## 対応状況

- Phase 1（基盤機能）: 完了
- Phase 2（タスク管理）: 運用中
- Phase 3（成績管理・シミュレーション）: 運用中
- Phase 4（シラバス自動取得との統合）: 実装予定

## 使い始め方

1. アプリを起動して Teams でログイン
2. プロフィールで所属情報（高専・学年・コース）を設定
3. タスク管理と成績管理を必要に応じて使い分け
4. オフライン時はローカル保存データを参照し、再接続時に同期

## 今後の予定

- Teams 課題の自動取り込み
- 単位修得シミュレーターの強化
- シラバス情報の自動取得と科目データ連携

## 関連ドキュメント

- ロードマップ: [../docs/roadmap.md](../docs/roadmap.md)
- シラバス連携設計: [../docs/blueprints/Backend_Syllabus_Parsing_Engine.md](../docs/blueprints/Backend_Syllabus_Parsing_Engine.md)
- 成績シミュレーション設計: [../docs/blueprints/Grade_Management_Simulation.md](../docs/blueprints/Grade_Management_Simulation.md)
- オフライン同期設計: [../docs/blueprints/offline_first_sync.md](../docs/blueprints/offline_first_sync.md)

## ライセンス

TBD（公開前に確定予定）
