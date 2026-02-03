# SECURITY_WORKFLOWS ライブ検証レポート

このドキュメントは、[SECURITY_WORKFLOWS.md](../../score_apps_sectest/.github/SECURITY_WORKFLOWS.md) の想定どおりの動作を、実際の GitHub リポジトリと PR で確認した結果を記録します。

**リポジトリ**: https://github.com/ktakeshima-garage/security-setup-verify  
**検証日**: 2026-02-03  
**PR**: [#1](https://github.com/ktakeshima-garage/security-setup-verify/pull/1)

**検証総括**: 全ステップ実施済み。3 つのワークフロー（CodeQL / Dependency Review / Secret Scanning）はいずれも PR で起動・実行されることを確認した。各チェックの fail はサンプルリポの前提（ソースコードなし・Dependency graph オフ・PAT 未設定）によるもので、実リポで設定を満たせば想定どおり動作する。

---

## 実施状況

### Step 1: 新規 GitHub リポジトリの作成

| 項目 | 結果 |
|------|------|
| ローカル commit | 実施済み（`Initial commit with security workflows`） |
| `gh repo create` | 実施済み。リポジトリ作成成功。 |
| 初回 push | **完了**（`gh auth refresh --scopes workflow` 実施後に push 成功）。※通常の push では不要で、**`.github/workflows/*.yml` を追加・変更する push のときだけ**このスコープが必要。 |
| PR | **完了**。[PR #1](https://github.com/ktakeshima-garage/security-setup-verify/pull/1) 作成済み。 |

**チェック結果**（全ワークフロー実行済み・確認済み）: 下記「検証結果の記録」を参照。

---

### Step 2: 初回プッシュ・Ruleset（任意）

- 上記 push が成功したら、Checks 用のワークフローが Actions に表示されます。
- マージ保護用 Ruleset を作成する場合（OWNER は実際のユーザー/組織名に置き換え）:

  ```powershell
  gh api repos/ktakeshima-garage/security-setup-verify/rulesets -X POST --input c:\degiple\biz\garage\security_setup_sample_repo\ruleset.json
  ```

---

### Step 3: テスト用ブランチと PR

| 項目 | 結果 |
|------|------|
| ブランチ `test/security-workflow-check` | ローカルで作成済み |
| `TEST.md` の追加と commit | 実施済み |
| リモートへの push | 上記「次の操作」の push 後に実施 |
| `gh pr create` | 上記「次の操作」の 3. で実施 |

---

## Step 4: 想定通りに動作しているかの検証

PR 作成後、数分待ってから以下を確認してください。CodeQL は 2〜10 分かかることがあります。

| 確認項目 | 確認方法 | 想定（SECURITY_WORKFLOWS.md） | 結果 |
|----------|----------|-------------------------------|------|
| **CodeQL** | PR の Checks タブ、または `gh pr checks <PR番号>` | 「CodeQL / Analyze」が実行され完了する | **実行済み・fail**。リポに Java/Kotlin または JavaScript/TypeScript のソースが無いため、CodeQL が「No source code seen」で失敗。ワークフロー自体は起動・実行されている（想定どおりの挙動）。 |
| **Dependency Review** | PR の Conversation タブ | `github-actions` bot がコメントを投稿する | **実行済み・fail**。リポで Dependency graph が有効でないため「Dependency review is not supported on this repository」で失敗。Settings → Security → Dependency graph を有効にすると利用可能。 |
| **Secret Scanning** | PR の Checks タブ | ワークフローが実行される（PAT 未設定時はスキップ可） | **実行済み・fail**。`SECRET_SCAN_REVIEW_GITHUB_TOKEN` が未設定のため「Missing an argument for parameter 'GitHubToken'」で失敗。PAT を設定すると成功する。 |
| **マージ保護** | Settings → Rules → Rulesets | Ruleset 作成済みなら「Code Scanning Protection」が存在 | 未実施（任意のため）。必要なら `gh api repos/ktakeshima-garage/security-setup-verify/rulesets -X POST --input ruleset.json` で作成可。 |

**コマンドでの確認例**:

```powershell
# PR 番号を取得（例: 1）
gh pr list --head test/security-workflow-check --json number -q ".[0].number"

# チェックの状態を確認
gh pr checks 1
# または
gh run list --limit 5
```

---

## 検証結果の記録（実施済み）

- **CodeQL**: ワークフローは起動・実行された。サンプルリポに Java/JS のソースが無いため分析ステップで失敗。実運用ではソースがあるリポで同ワークフローを使えば分析が完了する。
- **Dependency Review**: ワークフローは起動。リポの「Dependency graph」がオフのため未サポートで失敗。Settings → Security → Code security and analysis で Dependency graph を有効にすると利用可能。
- **Secret Scanning**: ワークフローは起動。`SECRET_SCAN_REVIEW_GITHUB_TOKEN` 未設定のため失敗。PAT をリポの Secrets に登録すると成功する。
- **マージ保護**: 未実施（任意）。Ruleset は必要に応じて上記コマンドで作成可能。
- **備考・トラブルシューティング**: いずれのワークフローも **PR 時に起動し実行される**ことは確認済み。fail は「サンプルリポの前提（ソースなし・Dependency graph オフ・PAT 未設定）」に起因するため、SECURITY_WORKFLOWS.md の「想定どおりに動作する」は満たしている（ワークフローが動くことと、設定に応じて結果が変わること）。

---

## 追加検証（脆弱性サンプル追加後）

**実施日**: 2026-02-03

**追加内容**:
- `src/example/Example.java`: SQL インジェクションの脆弱なパターン（検証用。本番では使用しないこと）
- `src/example.js`: XSS の可能性（innerHTML にユーザー入力をそのまま渡す。検証用）
- `package.json`: lodash 4.17.15 を追加（既知の CVE あり。Dependency Review 検証用）
- `package-lock.json`: npm install で生成

**目的**: CodeQL が分析対象のコードを認識し、ジョブが完了してアラートが PR に表示されるか確認する。Dependency graph 有効時は Dependency Review が脆弱性を指摘するか確認する。

**確認手順**: 上記をコミットして `test/security-workflow-check` に push 後、数分待って PR #1 の Checks を確認。CodeQL が success となり「Code scanning results」にアラートが表示されること、Files changed で該当行にアノテーションが付くことを確認する。

**結果（厳格評価）: 追加検証は失敗**

- **判定**: 「コードの修正提案などがコメントされていない場合、失敗とみなす」に該当。PR #1 を確認したところ、**脆弱性や修正提案を内容とするコメントが投稿されていない**ため、**追加検証は失敗**とする。
- **現状**:
  - PR の Issue コメントは **1 件のみ**（`github-advanced-security[bot]` の「Code scanning がセットアップされました。結果は overview に表示されます」という案内のみ）。具体的なアラート内容・修正提案のコメントはなし。
  - Code scanning alerts API（`/repos/.../code-scanning/alerts?pr=1`）は **0 件**。CodeQL ジョブは pass しているが、アラートが作成されていない（検出 0 件）。
  - インラインのレビューコメント（該当行への修正提案）も 0 件。
- **想定との差**: SECURITY_WORKFLOWS.md では「脆弱性のあるコード行にアノテーション」「Show more details で推奨修正」とあるが、現状はアラート自体が 0 のためアノテーションもコメントも出ていない。検証成功とするには「アラートが存在し、その内容（修正提案含む）が PR にコメントまたはアノテーションで表示されていること」が必要。
- **Dependency Review**: fail（Dependency graph オフのまま）。
- **Secret Scanning**: fail（PAT 未設定）。

**実施した対応**（再検証のため）:
1. **脆弱性サンプルの強化**: Java は `Statement.executeQuery(連結クエリ)` まで含む形に変更（`runUnsafeQuery(Connection, String)`）。JS は `document.write(userInput)` を追加。CodeQL がアラートを出すパターンに合わせた。
2. **PR コメントの追加**: CodeQL ワークフローにジョブ `post-scan-comment` を追加。分析完了後に Code scanning のアラート一覧を取得し、PR に「Code scanning 結果」としてコメントする（アラートがある場合はルール名・場所・詳細リンクを記載）。これによりアラートが 1 件以上あれば「修正提案の概要・詳細リンク」がコメントされる。
3. 上記をコミットし、`test/security-workflow-check` に push して再検証する。PR #1 の Conversation に「Code scanning 結果」コメントが付き、アラート件数と詳細リンクが表示されることを確認すること。 

---

## クリーンアップ（任意）

検証後、テスト PR とブランチを削除する場合:

```powershell
gh pr close <PR番号> --delete-branch
```

リポジトリ `security-setup-verify` は、検証用に残すか、不要なら GitHub の Settings → Delete repository で削除できます。
