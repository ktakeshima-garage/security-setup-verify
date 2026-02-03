# SECURITY_SETUP_GUIDE 検証レポート

このドキュメントは、[SECURITY_SETUP_GUIDE.md](../../score_apps_sectest/.github/SECURITY_SETUP_GUIDE.md) の手順を Windows (PowerShell) 環境で実施した際の検証結果をまとめたものです。

**検証日**: 2026-02-03  
**環境**: Windows / PowerShell  
**サンプルリポジトリ**: `security_setup_sample_repo`

---

## 検証結果サマリ

| Step | ガイドの記載のまま実行 | Windows での代替 | 推奨ガイド修正 |
|------|------------------------|------------------|----------------|
| Step 1 | ほぼ可能（変数は `$REPO`） | なし | PowerShell 用 `$REPO` 例を追記 |
| Step 2 | 2-1 の bash コマンドは不可 | 2-2 方法 B（ローカルで YAML 作成） | 「Windows では 2-1 をスキップし 2-2 方法 B を使う」と明記 |
| Step 3 | 3-1 の bash コマンドは不可 | ローカルで YAML 作成して push | 同様の注記を Step 3 に追記 |
| Step 4 | 4-3 の bash コマンドは不可 | ローカルで YAML 作成して push | 同様の注記を Step 4 に追記 |
| Step 5 | 5-1 の `/tmp` と `rm` は不可 | `ruleset.json` をカレント等に作成し `--input` で指定 | Windows 用手順を追記 |
| Step 6 | そのまま実行可能 | なし | 特になし |

---

## ステップ別詳細

### Step 1: 準備

- **1-2 リポジトリ名の設定**
  - Bash: `REPO="OWNER/REPO_NAME"`
  - PowerShell: `$REPO="OWNER/REPO_NAME"` で同様に利用可能。
- **1-3** `gh repo view $REPO --json name,isPrivate` は PowerShell でも `$REPO` で参照でき、そのまま実行可能。
- **1-4** CodeQL default setup の確認・無効化も `$REPO` を使えばそのまま実行可能。

**結論**: 実行可否。ガイドに PowerShell 用の変数設定例（`$REPO="OWNER/REPO_NAME"`）を追記すると親切。

---

### Step 2: CodeQL ワークフローの追加

- **2-1** `gh api` + heredoc + `base64 -w 0` は Bash 専用。PowerShell ではそのままでは動作しない。
- **2-2** 「Windows (PowerShell) の場合」として方法 B（ローカルで `.github/workflows/codeql.yml` を作成し commit/push）が既に記載されている。本サンプルリポジトリでは方法 B で追加済み。

**結論**: Windows では 2-1 をスキップし、2-2 方法 B を使用する。ガイドに「Windows の場合は 2-1 のコマンドは使わず、以下 2-2 方法 B で追加してください」と明記することを推奨。

---

### Step 3: Dependency Review ワークフローの追加

- **3-1** Step 2 と同様、`gh api` + heredoc + base64 は PowerShell では動作しない。
- 本サンプルでは `.github/workflows/dependency-review.yml` をローカルで作成し、ガイド記載の YAML をそのまま配置済み。

**結論**: Step 2 と同様、PowerShell の場合は 3-1 をスキップし、ローカルで YAML を作成して push する手順をガイドに追記することを推奨。

---

### Step 4: Secret Scanning ワークフローの追加（オプション）

- **4-2** `gh secret set SECRET_SCAN_REVIEW_GITHUB_TOKEN --repo $REPO` は、PowerShell で `$REPO` を設定した状態で実行可能。
- **4-3** ワークフローファイルの追加も、3-1 と同様に bash コマンドは不可。ローカルで `.github/workflows/secret-scanning-review.yml` を作成して push する形で検証可能。

**結論**: オプションのため検証は「実施する場合の手順が通るか」に限定。PowerShell では 4-3 もローカルで YAML 作成して push。ガイドに同様の注記を追記することを推奨。

---

### Step 5: マージ保護ルールの設定

- **5-1** `cat > /tmp/ruleset.json << 'EOF'` および `rm /tmp/ruleset.json` は Unix 専用。Windows には `/tmp` がなく、`rm` も標準では別扱い。
- **Windows での代替**:
  1. `ruleset.json` をカレントディレクトリ（または `$env:TEMP\ruleset.json`）に作成する。
  2. `gh api repos/$REPO/rulesets -X POST --input .\ruleset.json` で送信する。
  3. 削除は `Remove-Item .\ruleset.json` または残しても可。

本サンプルリポジトリには Step 5 用の `ruleset.json` を同梱済み。

**結論**: ガイドに「Windows の場合」として、一時ファイルを `%TEMP%\ruleset.json` またはカレントの `ruleset.json` に作成し、`gh api ... --input .\ruleset.json` で渡す手順を追記することを推奨。

---

### Step 6: 動作確認

- **6-1** `gh repo clone`, `git checkout -b`, `echo "# Security Test" >> TEST.md`, `git push -u origin ...` はいずれも PowerShell でそのまま実行可能。
- **6-2** `gh pr create ...` で PR 作成可能。
- **6-3** PR の Checks / Conversation で CodeQL・Dependency Review・Secret Scanning の結果を確認可能（Secret Scanning は PAT 設定時）。
- **6-4** `gh pr close --delete-branch` で問題なくクリーンアップ可能。

**結論**: そのまま実行可能。特段のガイド修正は不要。

---

## ガイド修正案（SECURITY_SETUP_GUIDE.md への追記）

上記検証に基づき、以下の追記を推奨します。

1. **Step 1（1-2 付近）**
   - PowerShell の場合の変数設定例: `$REPO="OWNER/REPO_NAME"`

2. **Step 2（2-1 の前または 2-2 の見出し付近）**
   - 「Windows (PowerShell) の場合は、以下の 2-1 コマンドは使えません。2-2 方法 B（ローカルでファイルを作成して push）を使用してください。」

3. **Step 3（3-1 の前または直後）**
   - 「Windows (PowerShell) の場合は 3-1 のコマンドをスキップし、Step 2 の方法 B と同様、ローカルで `.github/workflows/dependency-review.yml` を作成して push してください。」

4. **Step 4（4-3 の前または直後）**
   - 「Windows (PowerShell) の場合は 4-3 のコマンドをスキップし、同様にローカルで `.github/workflows/secret-scanning-review.yml` を作成して push してください。」

5. **Step 5（5-1 に続けて）**
   - 「**Windows の場合**: `cat` / `rm` は使えません。次のようにします。まず、この JSON を `ruleset.json` としてカレントディレクトリまたは `%TEMP%` に保存します。その後、`gh api repos/$REPO/rulesets -X POST --input .\ruleset.json` を実行します。不要なら `Remove-Item .\ruleset.json` で削除できます。」

以上を反映した具体的なパッチは、SECURITY_SETUP_GUIDE.md の更新として別途適用済みです。
