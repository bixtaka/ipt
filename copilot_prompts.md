# COPILOT_PROMPTS.md

> GitHub Copilot と Copilot Chat を「超スモールステップ」で運用するためのプロンプト集。  
> 各項目は **そのままコピペ** で使えます。受け入れ基準 (Acceptance Criteria) もセットで記載。

---

## 使い方（共通）
- **エディタ内生成**: 対象ファイルの先頭や該当箇所にコメントとして貼ると、直下に提案が出ます。
- **Copilot Chat**: `@workspace` または `@editor` を付けて実行すると、関連ファイルを見ながら変更提案が出ます。
- 迷ったら **「差分だけ出力して」「既存コードを壊さない」「ビルドが通るまで修正」** を添えると安定します。

---

## 1) 迷子の Gradle 構成を削除（構成クリーンアップ）
**Copilot Chat**
```
プロジェクト内の android/app/android/app/ ディレクトリにある古い Gradle 構成をすべて列挙して。これらはテンプレ重複なので削除対象。残すのは android/app/build.gradle.kts 側。削除してよいファイル一覧を出力して。
```
**Acceptance Criteria**
- 削除候補の一覧が出る
- `android/app/build.gradle.kts` が唯一の app モジュール定義になる

---

## 2) applicationId を固有化
> 例: `com.example.ipt` → `jp.yourcompany.ipt`

**`android/app/build.gradle.kts` の先頭コメント**
```kotlin
// Copilot: applicationId を jp.yourcompany.ipt に変更し、minSdk/targetSdk/namespace と矛盾が出ないように更新して。
// また AndroidManifest.xml の package も同名にそろえるパッチを提案して。
```
**Copilot Chat（補助）**
```
@workspace applicationId を jp.yourcompany.ipt に変更する。関連する AndroidManifest.xml の package も一致させる差分を作って。影響範囲があれば教えて。
```
**Acceptance Criteria**
- `defaultConfig.applicationId` が変更
- `android/app/src/main/AndroidManifest.xml` の `package` が一致

---

## 3) .gitignore を強化
**ルート `.gitignore` に追記**
```gitignore
# Copilot: Flutter/Android のローカル生成物を無視する項目を追加して。
# 例: android/.gradle/, android/local.properties, .kotlin/, build/, .dart_tool/ など。
```
**Acceptance Criteria**
- ローカル生成物が commit 対象から外れる

---

## 4) 共通バリデータを追加（`lib/utils/validators.dart`）
**ファイル先頭コメント**
```dart
// Copilot: 以下のバリデータ群を追加して。null/空文字、非負整数、非負小数、必須選択（ドロップダウン）。
// 戻り値は String?（エラー時メッセージ、正常時 null）。メッセージは日本語で統一。
```
**Acceptance Criteria**
- `requiredText`, `nonNegativeInt`, `nonNegativeDouble`, `requiredSelection` が生成
- 既存フォームで流用できる

---

## 5) SettingsPage を Form 方式へ統一
**`lib/ui/pages/settings_page.dart` の先頭コメント**
```dart
// Copilot: このページを Form + TextFormField ベースに統一し、validators.dart の関数を各フィールドに適用して。
// TextEditingController は UI 層に閉じ、保存ボタンで AppState.settings に反映する方式に変更して。
// 既存の onChanged 直書きは減らし、保存時にまとめて更新する設計に。
```
**Acceptance Criteria**
- 全入力が `Form`/`TextFormField` 化
- `validator:` に共通関数を適用
- 保存トリガで `context.read<AppState>().updateSettings(...)`

---

## 6) AppState の責務明確化（Undo 効かせたまま）
**`lib/state/app_state.dart` でコメント**
```dart
// Copilot: settings 更新用の updateSettings(copyWith) を追加。
// 変更前スナップショットをメメントに積んで undo/redo 維持。notifyListeners は最後に一度だけ。
```
**Acceptance Criteria**
- `updateSettings(JobSettings newSettings)` 追加
- Undo/Redo が壊れない
- 不要な `notifyListeners()` が無い

---

## 7) Selector で最小リビルド（パフォーマンス）
**`lib/ui/widgets/measurement_table.dart`**
```dart
// Copilot: Consumer 全体リビルドになっている箇所を Selector に分割し、行ウィジェット単位で最小リビルドに。
// 行には必要なフィールドのみ渡す。
```
**`lib/ui/widgets/stopwatch_controls.dart`**
```dart
// Copilot: 経過時間表示だけを Selector で購読し、ボタン UI はリビルドしない最適化に。
```
**Acceptance Criteria**
- `Selector<AppState, T>` が導入され、再描画が軽くなる

---

## 8) Excel 書式ヘルパの抽出
**`lib/services/excel/excel_exporter_io.dart`**
```dart
// Copilot: ヘッダ塗り、罫線、列幅自動、数値/日付スタイルを helper 関数に切り出し、export() 本体を短く読みやすくして。
```
**Acceptance Criteria**
- `applyHeaderStyle`, `applyBorder`, `autoFitColumns`, `numFmt` 等のヘルパ作成
- 重複記述が減る

---

## 9) Freezed + JSON でモデル堅牢化
**`pubspec.yaml`**
```yaml
# Copilot: freezed, freezed_annotation, json_serializable, build_runner を dev_dependencies に追加。
# Dart3/Flutter3.24 で動く安定版を提案して追記。
```
**`lib/models/job_settings.dart`**
```dart
// Copilot: このモデルを freezed に移行。fromJson/toJson, copyWith, ==/hashCode を自動生成。
// part ファイルと @freezed を正しく設定。既存フィールドは互換維持。
```
**Copilot Chat（補助）**
```
@workspace Windows での build_runner 実行例（watch 含む）と、生成物の出力先を教えて。
```
**Acceptance Criteria**
- `*.freezed.dart`/`*.g.dart` が生成
- 既存コードが `copyWith`/`fromJson` を利用可能

---

## 10) 共有処理の安全化（share_plus）
**共有呼び出し箇所**
```dart
// Copilot: share_plus 呼び出しを try-catch でラップし、Web/IO で分岐する safeShare(...) ヘルパーを追加して。
// 失敗時は SnackBar で日本語メッセージを表示。
```
**Acceptance Criteria**
- 例外でクラッシュしない
- どの画面からも同一ヘルパを利用

---

## 11) Lints を強化
**`analysis_options.yaml`**
```yaml
# Copilot: 以下を追加/有効化: prefer_const_constructors, avoid_print, unawaited_futures, use_build_context_synchronously, always_declare_return_types。
# 自動修正候補(Quick Fix)のコメントも示して。
```
**Acceptance Criteria**
- 警告が増えるが修正導線が明確

---

## 12) Conventional Commits で小さくコミット
**Copilot Chat**
```
この変更群を小さくコミットする。Conventional Commits で日本語サマリを提案して。例:
- feat: 設定画面をForm化して共通バリデータ適用
- perf: Selector導入でテーブルの再ビルド削減
- chore: duplicate Gradle構成を削除
```
**Acceptance Criteria**
- 意味のある粒度で履歴が残る

---

## 付録: よく使うフレーズ
- 差分だけ出力して
- 既存コードを壊さない
- ビルドが通るまで修正
- 影響範囲を説明して
- テスト観点と受け入れ基準も出して

