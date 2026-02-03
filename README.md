# Security Setup Sample Repo

SECURITY_SETUP_GUIDE.md の手順を検証するためのサンプルリポジトリです。

## 使い方

1. GitHub 上で新規リポジトリを作成する
2. このディレクトリで `git remote add origin <リポジトリURL>` を実行
3. [SECURITY_SETUP_GUIDE.md](../score_apps_sectest/.github/SECURITY_SETUP_GUIDE.md) の Step 1〜6 に従ってセットアップを実施する

## 含まれるもの

- セキュリティワークフロー（CodeQL / Dependency Review / Secret Scanning）のサンプル
- Step 6 の Dependency Review 確認用の `package.json`
- Step 5 用の `ruleset.json` サンプル
- 検証結果: [.github/VERIFICATION_REPORT.md](.github/VERIFICATION_REPORT.md)
- ライブ検証（GitHub リポ・PR）: [.github/LIVE_VERIFICATION.md](.github/LIVE_VERIFICATION.md)
