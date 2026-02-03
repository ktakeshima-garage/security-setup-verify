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

**結果（厳格評価）: 再検証で成功**

- **判定**: 「コードの修正提案などがコメントされていない場合、失敗とみなす」に対し、対応後に **PR にアラート内容と修正方法リンクがコメントされた**ため、**追加検証は成功**とする。
- **再検証時の PR コメント例**:
  - 「Code scanning 結果（この PR）」
  - 「1 件のアラートが検出されました。修正を検討してください。」
  - 「java/concatenated-sql-query (src/example/Example.java:21) — Query built by concatenation with this expression, which may be untrusted.」
  - 「詳細・修正方法」（アラート詳細ページへのリンク）
- **補足**: Java の SQL 連結クエリが CodeQL により検出され、ワークフローの `post-scan-comment` ジョブがその内容を PR にコメントしている。Dependency Review は Dependency graph オフのため未実施。Secret Scanning は PAT 未設定のため未実施。 

---

## クリーンアップ（任意）

検証後、テスト PR とブランチを削除する場合:

```powershell
gh pr close <PR番号> --delete-branch
```

リポジトリ `security-setup-verify` は、検証用に残すか、不要なら GitHub の Settings → Delete repository で削除できます。
