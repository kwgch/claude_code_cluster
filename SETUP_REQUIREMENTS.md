# Claude Code Parallel Execution Environment - Setup Requirements

## Required Components

### 1. System Requirements
- **Node.js**: v14.0.0 or higher (recommended: v16+)
- **npm**: v6.0.0 or higher
- **OS**: Linux, macOS, Windows (WSL recommended)
- **Claude CLI**: Installed (`claude` command available)

### 2. Required Packages
```json
{
  "dependencies": {
    "node-pty": "^1.0.0"  // PTY (pseudo-terminal) support
  }
}
```

### 3. Directory Structure
```
project/
├── package.json                    # Node.js project configuration
├── parallel_claude_runner.js       # Main execution script
├── setup_node_runner.sh           # Setup script
├── worker[N]_instructions.md      # Worker instruction files
├── logs/                          # Worker log output
├── comm/                          # Inter-worker communication files
└── outputs/                       # Deliverables output directory
```

## Setup Instructions

### 1. Quick Setup (Recommended)
```bash
# Run the setup script
chmod +x setup_node_runner.sh
./setup_node_runner.sh
```

### 2. Manual Setup
```bash
# If package.json doesn't exist
npm init -y

# Install node-pty
npm install node-pty

# Grant execution permissions
chmod +x parallel_claude_runner.js

# Create required directories
mkdir -p logs comm outputs/{development,research,content,reports,temp}
```

## Usage

### Basic Execution
```bash
# Run with 2 workers
node parallel_claude_runner.js worker1_instructions.md worker2_instructions.md

# Run with 6 workers
node parallel_claude_runner.js worker{1..6}_instructions.md
```

### Test Execution
```bash
# Verify functionality with simple test tasks
node parallel_claude_runner.js test_worker1_instructions.md test_worker2_instructions.md
```

## Troubleshooting

### node-pty Build Errors
```bash
# If build tools are needed (Ubuntu/Debian)
sudo apt-get install build-essential

# For macOS
xcode-select --install
```

### Claude CLI Not Found
```bash
# Check if Claude CLI is installed
which claude

# Add to PATH if not found
export PATH="$PATH:/path/to/claude"
```

### Permission Errors
```bash
# Grant execution permissions
chmod +x parallel_claude_runner.js
chmod +x setup_node_runner.sh
```

## Environment Variables (Optional)

```bash
# Custom Claude CLI path
export CLAUDE_CLI_PATH="/custom/path/to/claude"

# Limit maximum workers
export MAX_CLAUDE_WORKERS=8

# Log level
export DEBUG=true
```

## Verification

### ✅ Setup Completion Checklist
- [ ] Node.js v14+ installed
- [ ] Claude CLI available (`claude --help` works)
- [ ] `npm install` successful
- [ ] `node-pty` installed
- [ ] Required directories created
- [ ] Scripts have execution permissions

### ✅ Functionality Check
- [ ] `node test_pty_runner.js` TTY test passes
- [ ] Test workers start and stop properly
- [ ] Log files are generated
- [ ] Status files are updated

## Next Steps

1. **Create Worker Instructions**: Create `worker[N]_instructions.md` files
2. **Define Task**: Define main task in `task.md`
3. **Execute in Parallel**: Run with `node parallel_claude_runner.js`
4. **Monitor Progress**: Watch real-time progress
5. **Collect Results**: Get deliverables from `outputs/` directory