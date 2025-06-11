# 🚀 Claude Code 並列実行 - クイックスタート

## 必要なもの（3つだけ！）

1. **Node.js** (v14以上)
2. **Claude CLI** (インストール済み)
3. **このリポジトリ**

## 30秒セットアップ

```bash
# 1. セットアップ実行（依存関係の自動インストール）
./setup_node_runner.sh

# 2. テスト実行
node parallel_claude_runner.js test_worker1_instructions.md test_worker2_instructions.md

# 3. 本番実行（例：6ワーカーでフルスタックアプリ開発）
node parallel_claude_runner.js worker{1..6}_instructions.md
```

## 何ができるか

### 🎯 本質
**1つのClaude Codeが、必要なだけ自分の分身を作り、並列で作業する**

### 📊 例：フルスタックアプリ開発
- **従来**: 1人のClaude Codeが順番に作業 → 6時間
- **並列化**: 6人のClaude Codeが同時作業 → 1時間

## ファイル構成

```
📁 必須ファイル
├── 📄 parallel_claude_runner.js    # メインプログラム
├── 📄 setup_node_runner.sh        # セットアップ
└── 📄 worker*_instructions.md     # 各ワーカーへの指示

📁 自動生成
├── 📂 logs/      # 各ワーカーのログ
├── 📂 comm/      # ワーカー間通信
└── 📂 outputs/   # 成果物
```

## トラブルシューティング

### ❌ "Raw mode is not supported" エラー
→ ✅ node-ptyが解決済み！

### ❌ claude: command not found
→ Claude CLIをインストール: `npm install -g @anthropic-ai/claude-code`

### ❌ node-pty のビルドエラー
→ ビルドツールをインストール:
```bash
# Ubuntu/Debian
sudo apt-get install build-essential

# macOS
xcode-select --install
```

## 監視方法

実行中は自動的にステータスが表示されます：
```
=== PARALLEL CLAUDE WORKER MONITOR ===
Time: 2025-06-11 15:30:00

🟢 Worker 1 (PID: 12345, Runtime: 120s)
   Status: Backend API 実装中...

🟢 Worker 2 (PID: 12346, Runtime: 118s)
   Status: React コンポーネント作成中...

Progress: 2/6 workers completed
```

## 次のステップ

1. **task.md** を作成してメインタスクを定義
2. ワーカー数は自動決定（CPUとメモリに基づく）
3. 各ワーカーの成果物は `outputs/` に保存

---

💡 **ヒント**: まずはテストワーカー2つで動作確認してから、本格的なタスクに挑戦しましょう！