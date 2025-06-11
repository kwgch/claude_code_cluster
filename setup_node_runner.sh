#!/bin/bash

echo "🔧 Setting up Node.js Parallel Claude Runner"
echo "==========================================="

# Check if node is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 14+ first."
    exit 1
fi

echo "✅ Node.js version: $(node --version)"

# Install dependencies
echo ""
echo "📦 Installing dependencies..."
npm install

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully"
else
    echo "❌ Failed to install dependencies"
    exit 1
fi

# Make scripts executable
chmod +x parallel_claude_runner.js

# Create test instruction files if they don't exist
echo ""
echo "📝 Creating test instruction files..."

if [ ! -f "test_worker1_instructions.md" ]; then
    cat > test_worker1_instructions.md << 'EOF'
# Test Worker 1 Instructions

## Your Role
You are Worker 1 in a test of the parallel Claude CLI system.

## Your Assignment
Create a simple "Hello World" application and report your progress.

## Requirements
1. Create a simple Node.js hello world script
2. Test that it runs correctly
3. Write your output to outputs/test/worker1/

## Communication Protocol
- Write status updates to: `comm/worker1_status.txt`
- Format: `echo "[Worker1] Status: Your message" >> comm/worker1_status.txt`
- Report progress every few minutes
- Mark completion with: `echo "[Worker1] COMPLETED: Task finished" >> comm/worker1_status.txt`

## Deliverables
1. hello.js file with console.log("Hello from Worker 1!")
2. package.json if needed
3. Progress reports in status file
EOF
fi

if [ ! -f "test_worker2_instructions.md" ]; then
    cat > test_worker2_instructions.md << 'EOF'
# Test Worker 2 Instructions

## Your Role
You are Worker 2 in a test of the parallel Claude CLI system.

## Your Assignment
Create a simple Python script and report your progress.

## Requirements
1. Create a simple Python hello world script
2. Test that it runs correctly
3. Write your output to outputs/test/worker2/

## Communication Protocol
- Write status updates to: `comm/worker2_status.txt`
- Format: `echo "[Worker2] Status: Your message" >> comm/worker2_status.txt`
- Report progress every few minutes
- Mark completion with: `echo "[Worker2] COMPLETED: Task finished" >> comm/worker2_status.txt`

## Deliverables
1. hello.py file with print("Hello from Worker 2!")
2. Progress reports in status file
EOF
fi

# Create test directories
mkdir -p outputs/test/{worker1,worker2}
mkdir -p logs comm

echo "✅ Test instruction files created"

echo ""
echo "🚀 Setup complete! You can now run:"
echo ""
echo "   # Test with 2 workers:"
echo "   node parallel_claude_runner.js test_worker1_instructions.md test_worker2_instructions.md"
echo ""
echo "   # Or use the original instruction files:"
echo "   node parallel_claude_runner.js worker1_instructions.md worker2_instructions.md worker3_instructions.md"
echo ""
echo "📋 Features of this runner:"
echo "   ✅ Uses node-pty to provide proper TTY environment"
echo "   ✅ Solves 'Raw mode is not supported' error"
echo "   ✅ Real-time monitoring of worker progress"
echo "   ✅ File-based communication between workers"
echo "   ✅ Graceful shutdown with Ctrl+C"
echo "   ✅ Automatic cleanup of resources"
echo ""
echo "🔍 Monitor files:"
echo "   - logs/worker*.log     (Full Claude CLI output)"
echo "   - comm/worker*_status.txt (Worker status updates)"
echo "   - comm/worker*.pid     (Process IDs)"