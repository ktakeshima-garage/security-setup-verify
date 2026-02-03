# SECURITY_WORKFLOWS ライブ検証レポート

このドキュメントは、[SECURITY_WORKFLOWS.md](../../score_apps_sectest/.github/SECURITY_WORKFLOWS.md) の想定どおりの動作を、実際の GitHub リポジトリと PR で確認した結果を記録します。

**リポジトリ**: https://github.com/ktakeshima-garage/security-setup-verify  
**検証日**: 2026-02-03

---

## 実施状況

### Step 1: 新規 GitHub リポジトリの作成

| 項目 | 結果 |
|------|------|
| ローカル commit | 実施済み（`Initial commit with security workflows`） |
| `gh repo create` | 実施済み。リポジトリ作成成功。 |
| 初回 push | **未完了**。workflow スコープ不足のため push がリモートで拒否されました。 |

**次の操作（必須）**: ワークフロー付きの push を行うには、`workflow` スコープが必要です。

1. ターミナルで次を実行し、ブラウザで認証を完了してください。

   ```powershell
   gh auth refresh --scopes workflow --hostname github.com
   ```

2. 続けて以下を実行し、master とテストブランチを push してください。

   ```powershell
   cd c:\degiple\biz\garage\security_setup_sample_repo
   git push -u origin master
   git push -u origin test/security-workflow-check
   ```

3. PR を作成します。

   ```powershell
   gh pr create --title "test: Verify security workflows" --body "SECURITY_WORKFLOWS.md の動作確認用 PR です。"
   ```

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

| 確認項目 | 確認方法 | 想定（SECURITY_WORKFLOWS.md） | 結果（記入） |
|----------|----------|-------------------------------|--------------|
| **CodeQL** | PR の Checks タブ、または `gh pr checks <PR番号>` | 「CodeQL / Analyze (java-kotlin)」「CodeQL / Analyze (javascript-typescript)」が実行され完了する |  |
| **Dependency Review** | PR の Conversation タブ | `github-actions` bot が「Dependency Review」のコメントを投稿する（依存変更がなければ「No dependency changes」等でも可） |  |
| **Secret Scanning** | PR の Checks タブ | ワークフローが実行される（PAT 未設定の場合はスキップまたは警告でも可） |  |
| **マージ保護** | Settings → Rules → Rulesets | Ruleset 作成済みなら「Code Scanning Protection」が存在する |  |

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

## 検証結果の記録（実施後に記入）

- **CodeQL**: 
- **Dependency Review**: 
- **Secret Scanning**: 
- **マージ保護**: 
- **備考・トラブルシューティング**: 

---

## クリーンアップ（任意）

検証後、テスト PR とブランチを削除する場合:

```powershell
gh pr close <PR番号> --delete-branch
```

リポジトリ `security-setup-verify` は、検証用に残すか、不要なら GitHub の Settings → Delete repository で削除できます。
