# 📚 高専ナビ データ作成・運用ガイド

このプロジェクトでは、学科リストと各校のシラバスデータを分離して管理しています。
正しいフォーマットと**バージョン管理ルール**に従うことで、全ユーザーに最新の評価データが自動配信されます。

---

## 📂 ディレクトリ構成

1. **/config/course_data/**: 学校ごとの学科・コース定義
2. **/config/syllabus_data/**: 学校/学年/コースごとのシラバス定義

例:

```text
/config/syllabus_data/
  ├─ nagano/
  │   ├─ 1/
  │   │   └─ eng_common.json
  │   ├─ 2/
  │   │   └─ info_elec.json
  │   └─ 3/
  │       └─ info_elec_info.json
  └─ tokyo/
      ├─ 1/
      │   └─ info.json
      └─ ...
```

---

## 🔄 バージョン管理（version）の運用ルール

各JSONファイルの冒頭にある `"version": "1.0"` は、データの更新をアプリに知らせるための重要な指標です。

### 更新のタイミング
- **年度更新**: 新年度のシラバスに合わせてデータを書き換えた場合。
- **誤字・比率修正**: 既存データのミスを修正した場合。
- **科目追加**: 新しい科目をリストに追加した場合。

### 記述ルール
1.  **数値を上げる**: データを更新したら、必ず数値を増やしてください（例: `1.0` → `1.1`）。
2.  **適用単位**: version は「コースJSONファイル単位」で管理します。
3.  **注意**: 数値を上げ忘れると、データを書き換えてもユーザーの端末には古いデータが表示され続けます。

---

## 🛠 データの記述形式

### 1. 学科・コース定義 (`/config/course_data/[学校].json`)
```json
{
  "kosenId": "nagano",
  "kosenName": "長野工業高等専門学校",
  "aliases": ["長野高専", "長野"],
  "version": "1.0",
  "grades": {
    "1": [{"id": "eng_common", "displayName": "工学科"}],
    "2": [{"id": "info_elec", "displayName": "情報エレクトロニクス(IE)系"}],
    "3": [{"id": "info_elec_info", "displayName": "情報エレクトロニクス(IE)系（情報コース）"}]
  }
}
```

### 2. シラバスデータ (`/config/syllabus_data/[学校]/[学年]/[courseId].json`)
```json
{
  "grade": "3",
  "courseId": "info_elec_info",
  "version": "1.1", // 更新したら必ず数値を上げる
  "subjects": [
    {
      "subjectId": "nagano_3_info_mathA",
      "name": "基礎数学A",
      "evaluations": [
        { "id": "exam", "name": "定期試験", "ratio": 70 },
        { "id": "normal", "name": "平常点", "ratio": 30 }
      ]
    }
  ]
}
```

## ✍️ evaluations（評価項目）のUIルール

id の値によって、アプリの入力画面が自動的に切り替わります。

### id: "exam" の場合

「第1回〜第4回」のテスト点入力欄を生成します。

### id: "exam" 以外（normal, report, quiz 等）の場合

**「数値入力 + シミュレーション用スライダー」**を生成します。

## ⚠️ 提出前チェックリスト

- [ ] 比率合計: 1つの科目内の ratio 合計は必ず 100 になっていますか？
- [ ] バージョン: 修正・更新の場合、対象コースJSONの version 数値は前より増えていますか？
- [ ] 配置場所: `syllabus_data/[学校]/[学年]/[courseId].json` に正しく配置されていますか？
- [ ] ID一致: syllabus_data の courseId は course_data の id と一致していますか？

これで、他の開発者がデータを修正した際も「バージョンを上げ忘れて反映されない」といったトラブルを防げるようになります。

