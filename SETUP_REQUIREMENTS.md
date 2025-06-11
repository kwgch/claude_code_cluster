# Claude Code 並列実行環境 セットアップ要件

## 必須要件

### 1. システム要件
- **Node.js**: v14.0.0 以上（推奨: v16以上）
- **npm**: v6.0.0 以上
- **OS**: Linux, macOS, Windows (WSL推奨)
- **Claude CLI**: インストール済み（`claude` コマンドが使用可能）

### 2. 必要なパッケージ
```json
{
  "dependencies": {
    "node-pty": "^1.0.0"  // PTY（擬似端末）サポート
  }
}
```

### 3. ディレクトリ構造
```
project/
├── package.json                    # Node.js プロジェクト設定
├── parallel_claude_runner.js       # メイン実行スクリプト
├── setup_node_runner.sh           # セットアップスクリプト
├── worker[N]_instructions.md      # 各ワーカーへの指示書
├── logs/                          # ワーカーログ出力
├── comm/                          # ワーカー間通信ファイル
└── outputs/                       # 成果物出力ディレクトリ
```

## セットアップ手順

### 1. クイックセットアップ（推奨）
```bash
# セットアップスクリプトを実行
chmod +x setup_node_runner.sh
./setup_node_runner.sh
```

### 2. 手動セットアップ
```bash
# package.json が存在しない場合
npm init -y

# node-pty をインストール
npm install node-pty

# スクリプトに実行権限を付与
chmod +x parallel_claude_runner.js

# 必要なディレクトリを作成
mkdir -p logs comm outputs/{development,research,content,reports,temp}
```

## 使用方法

### 基本的な実行
```bash
# 2つのワーカーで実行
node parallel_claude_runner.js worker1_instructions.md worker2_instructions.md

# 6つのワーカーで実行
node parallel_claude_runner.js worker{1..6}_instructions.md
```

### テスト実行
```bash
# テスト用の簡単なタスクで動作確認
node parallel_claude_runner.js test_worker1_instructions.md test_worker2_instructions.md
```

## トラブルシューティング

### node-pty のビルドエラー
```bash
# ビルドツールが必要な場合（Ubuntu/Debian）
sudo apt-get install build-essential

# macOS の場合
xcode-select --install
```

### Claude CLI が見つからない
```bash
# Claude CLI がインストールされているか確認
which claude

# パスが通っていない場合は追加
export PATH="$PATH:/path/to/claude"
```

### 権限エラー
```bash
# 実行権限を付与
chmod +x parallel_claude_runner.js
chmod +x setup_node_runner.sh
```

## 環境変数（オプション）

```bash
# Claude CLI のカスタムパス
export CLAUDE_CLI_PATH="/custom/path/to/claude"

# 最大ワーカー数の制限
export MAX_CLAUDE_WORKERS=8

# ログレベル
export DEBUG=true
```

## 確認事項

### ✅ セットアップ完了チェックリスト
- [ ] Node.js v14+ がインストールされている
- [ ] Claude CLI が利用可能（`claude --help` が動作）
- [ ] `npm install` が成功
- [ ] `node-pty` がインストールされている
- [ ] 必要なディレクトリが作成されている
- [ ] スクリプトに実行権限がある

### ✅ 動作確認
- [ ] `node test_pty_runner.js` でTTYテストが成功
- [ ] テストワーカーが正常に起動・終了
- [ ] ログファイルが生成される
- [ ] ステータスファイルが更新される

## 次のステップ

1. **ワーカー指示書の作成**: `worker[N]_instructions.md` を作成
2. **タスクの定義**: `task.md` でメインタスクを定義
3. **並列実行**: `node parallel_claude_runner.js` で実行
4. **モニタリング**: リアルタイムで進捗を確認
5. **結果の収集**: `outputs/` ディレクトリから成果物を取得