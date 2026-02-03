# SECURITY_WORKFLOWS 検証用スクリプト
# 実行: .\run-github-verification.ps1
# 前提: gh auth login 済み、gh auth refresh --scopes workflow 済み

$ErrorActionPreference = "Stop"
$RepoName = "security-setup-verify"

Set-Location $PSScriptRoot

# Step 0: 未コミットがあればコミット
$status = git status --porcelain
if ($status) {
    git add -A
    git commit -m "Initial commit with security workflows"
}

# Step 1: リモートがなければ GitHub にリポジトリ作成して push
$remote = git remote get-url origin 2>$null
$currentBranch = git rev-parse --abbrev-ref HEAD
if (-not $remote) {
    gh repo create $RepoName --public --source=. --remote=origin --push
} else {
    git push -u origin $currentBranch
}

# OWNER を取得（gh repo view で）
$owner = (gh repo view --json owner -q ".owner.login")
$fullRepo = "${owner}/${RepoName}"

# Step 2: Ruleset 作成（オプション）
if (Test-Path ".\ruleset.json") {
    gh api "repos/$fullRepo/rulesets" -X POST --input .\ruleset.json 2>$null
}

# Step 3: テストブランチと PR
git checkout -b test/security-workflow-check 2>$null
if (-not (Test-Path "TEST.md")) {
    Add-Content -Path "TEST.md" -Value "# Security Test"
    git add TEST.md
    git commit -m "test: Verify security workflows"
}
git push -u origin test/security-workflow-check
$pr = gh pr create --title "test: Verify security workflows" --body "SECURITY_WORKFLOWS.md の動作確認用 PR です。"
Write-Host "PR created: $pr"

# PR 番号を取得
$prNumber = (gh pr list --head test/security-workflow-check --json number -q ".[0].number")
Write-Host "PR #$prNumber - 数分待ってから以下でチェックを確認:"
Write-Host "  gh pr checks $prNumber"
Write-Host "  gh run list --limit 5"
