# 🚀 Claude Code Parallel Execution - Quick Start

## Requirements (Only 3!)

1. **Node.js** (v14+)
2. **Claude CLI** (installed)
3. **This repository**

## 30-Second Setup

```bash
# 1. Run setup (auto-installs dependencies)
./setup_node_runner.sh

# 2. Test run
node parallel_claude_runner.js test_worker1_instructions.md test_worker2_instructions.md

# 3. Production run (example: full-stack app with 6 workers)
node parallel_claude_runner.js worker{1..6}_instructions.md
```

## What It Can Do

### 🎯 The Essence
**One Claude Code creates as many clones as needed to work in parallel**

### 📊 Example: Full-Stack App Development
- **Traditional**: 1 Claude Code works sequentially → 6 hours
- **Parallelized**: 6 Claude Codes work simultaneously → 1 hour

## File Structure

```
📁 Required Files
├── 📄 parallel_claude_runner.js    # Main program
├── 📄 setup_node_runner.sh        # Setup script
└── 📄 worker*_instructions.md     # Worker instructions

📁 Auto-generated
├── 📂 logs/      # Worker logs
├── 📂 comm/      # Inter-worker communication
└── 📂 outputs/   # Deliverables
```

## Troubleshooting

### ❌ "Raw mode is not supported" error
→ ✅ Solved with node-pty!

### ❌ claude: command not found
→ Install Claude CLI: `npm install -g @anthropic-ai/claude-code`

### ❌ node-pty build errors
→ Install build tools:
```bash
# Ubuntu/Debian
sudo apt-get install build-essential

# macOS
xcode-select --install
```

## Monitoring

Status is automatically displayed during execution:
```
=== PARALLEL CLAUDE WORKER MONITOR ===
Time: 2025-06-11 15:30:00

🟢 Worker 1 (PID: 12345, Runtime: 120s)
   Status: Implementing backend API...

🟢 Worker 2 (PID: 12346, Runtime: 118s)
   Status: Creating React components...

Progress: 2/6 workers completed
```

## Next Steps

1. Create **task.md** to define your main task
2. Worker count is auto-determined (based on CPU and memory)
3. Each worker's outputs are saved in `outputs/`

---

💡 **Tip**: Start with 2 test workers to verify everything works before tackling bigger tasks!