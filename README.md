# Claude Code Parallel Execution Framework

A framework that enables **Claude Code to dynamically spawn multiple instances to work in parallel**, dramatically improving efficiency for complex projects.

## 🚀 Quick Start

```bash
# 1. Setup (auto-installs dependencies)
./setup_node_runner.sh

# 2. Run with your instruction files
node parallel_claude_runner.js worker1_instructions.md worker2_instructions.md

# 3. Or run with multiple workers
node parallel_claude_runner.js worker{1..6}_instructions.md
```

## 📋 Requirements

- **Node.js** v14+ (recommended v16+)
- **Claude CLI** installed and accessible
- **Unix-like OS** (Linux, macOS, or WSL for Windows)

## 🏗️ Architecture

```
┌─────────────────┐
│  Manager Claude │ (You)
└────────┬────────┘
         │ Creates instructions & manages processes
         │
    ┌────┴────┬────────┬────────┐
    ▼         ▼        ▼        ▼
┌─────────┐┌─────────┐┌─────────┐┌─────────┐
│Worker 1 ││Worker 2 ││Worker 3 ││Worker N │
└─────────┘└─────────┘└─────────┘└─────────┘
    │         │        │        │
    └─────────┴────────┴────────┘
              │
         File-based communication
         (comm/*.txt)
```

## 💡 Core Value Proposition

1. **Dynamic Scaling**: Automatically launches optimal number of Claude instances based on task complexity
2. **True Parallel Processing**: Each instance works independently while coordinating through files
3. **Efficiency Maximization**: Reduces complex project completion time dramatically

### Example: Full-Stack Application
- **Traditional**: 1 Claude Code works sequentially → 6 hours
- **Parallelized**: 6 Claude Codes work simultaneously → 1 hour

## 🔧 Technical Implementation

### The Problem
Claude CLI requires an interactive terminal (TTY) and fails in background processes with:
```
Error: Raw mode is not supported on the current process.stdin
```

### The Solution
Using `node-pty` library to provide pseudo-terminal environment for each Claude instance:

```javascript
const ptyProcess = pty.spawn('claude', [instructions], {
    name: 'xterm-color',
    env: { TERM: 'xterm-256color' }
});
```

## 📂 Project Structure

```
/workspaces/cc_parallel/
├── parallel_claude_runner.js    # Main execution script
├── setup_node_runner.sh        # Setup script
├── start.sh                    # Simple Claude launcher
├── task.md                     # Task definition (sample)
├── worker*_instructions.md     # Worker instructions
├── logs/                       # Worker execution logs
├── comm/                       # Inter-worker communication
└── outputs/                    # Task deliverables
```

## 🎯 Usage Patterns

### 1. Large-Scale Development
```bash
Worker 1: Backend API development
Worker 2: Frontend UI implementation  
Worker 3: Authentication system
Worker 4: Real-time features
Worker 5: Test suite creation
Worker 6: Dockerization and documentation
```

### 2. Research & Analysis
```bash
Worker 1: Technical research and prototyping
Worker 2: Competitive analysis
Worker 3: Security evaluation
Worker 4: Performance optimization
```

### 3. Content Generation
```bash
Worker 1: API reference generation
Worker 2: Tutorial creation
Worker 3: Sample code development
Worker 4: Integration and review
```

## 📝 Creating Worker Instructions

### Using the Template
Create `worker[N]_instructions.md` files with:

```markdown
# Worker [NUMBER] Instructions

## Your Assignment
[Specific task description]

## Requirements
1. [Requirement 1]
2. [Requirement 2]
3. [Requirement 3]

## Deliverables
- [Deliverable 1]
- [Deliverable 2]

## Communication Protocol
- Write status updates to: comm/worker[NUMBER]_status.txt
- Format: echo '[Worker[NUMBER]] Status: Your message' >> comm/worker[NUMBER]_status.txt
- Mark completion with: COMPLETED: when done

## Output Location
Save all work to: outputs/[category]/
```

## 📊 Monitoring

Real-time monitoring displays:
```
=== PARALLEL CLAUDE WORKER MONITOR ===
Time: 2025-06-11 15:30:00

🟢 Worker 1 (PID: 12345, Runtime: 120s)
   Status: Implementing backend API...

🟢 Worker 2 (PID: 12346, Runtime: 118s)
   Status: Creating React components...

Progress: 2/6 workers completed
```

## 🛠️ Setup Details

### Automatic Setup
```bash
chmod +x setup_node_runner.sh
./setup_node_runner.sh
```

### Manual Setup
```bash
# Initialize Node.js project
npm init -y

# Install dependencies
npm install node-pty

# Create directories
mkdir -p logs comm outputs

# Make scripts executable
chmod +x parallel_claude_runner.js setup_node_runner.sh start.sh
```

## 🐛 Troubleshooting

### Common Issues

1. **"Raw mode is not supported" error**
   - ✅ Already solved with node-pty implementation

2. **"claude: command not found"**
   ```bash
   # Check installation
   which claude
   
   # If not found, install Claude CLI
   npm install -g @anthropic-ai/claude-code
   ```

3. **node-pty build errors**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install build-essential
   
   # macOS
   xcode-select --install
   ```

4. **Permission errors**
   ```bash
   chmod +x parallel_claude_runner.js
   chmod +x setup_node_runner.sh
   ```

## ⚙️ Environment Variables (Optional)

```bash
# Custom Claude CLI path
export CLAUDE_CLI_PATH="/custom/path/to/claude"

# Limit maximum workers
export MAX_CLAUDE_WORKERS=8

# Enable debug logging
export DEBUG=true
```

## 🎯 Best Practices

1. **Start Small**: Test with 2 workers before scaling up
2. **Resource Management**: Each worker uses ~1-2GB memory
3. **Task Division**: Break complex tasks into independent subtasks
4. **Communication**: Use status files for coordination
5. **Output Organization**: Keep deliverables in structured directories

## 🚀 Advanced Usage

### Dynamic Task Distribution
Define your main task in `task.md` and let the system determine optimal worker count:

```markdown
# Task Specification

### Task Type
development

### Task Description
Create a full-stack todo application

### Specific Requirements
1. Backend: Node.js with Express
2. Frontend: React with TypeScript
3. Real-time updates using WebSocket
4. Docker configuration
5. Comprehensive tests

### Task Distribution Plan
- Pane 1: Backend API development
- Pane 2: Frontend UI implementation
- Pane 3: Authentication and real-time
- Pane 4: Testing and deployment
```

## 📈 Performance Metrics

- **Parallel Speedup**: Up to N× faster with N workers
- **Resource Usage**: ~2GB memory per worker
- **Optimal Workers**: 2-8 depending on system specs
- **Communication Overhead**: Minimal (file-based)

## 🔒 Security Considerations

- Workers operate in isolated processes
- Use `--dangerously-skip-permissions` flag cautiously
- Consider containerization for production use
- Monitor resource usage to prevent system overload

## 🤝 Contributing

This project is designed to be minimal and efficient. When contributing:
1. Keep the codebase simple and maintainable
2. Document any new features clearly
3. Test with multiple worker configurations
4. Ensure backward compatibility

## 📜 License

This project is open source. Use it to maximize your Claude Code productivity!

---

💡 **Pro Tip**: Start with 2-4 workers for most tasks. Scale up only when you understand the resource requirements and task dependencies.