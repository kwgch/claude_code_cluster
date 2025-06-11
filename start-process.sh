#!/bin/bash

# Claude Code Task Management System - Process Mode Launcher
# This script launches Claude Code for process-based multi-instance execution

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Display banner
echo
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Claude Code Task Management System - Process Mode      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo

# Check if task.md exists and has a task description
if [ -f "task.md" ]; then
    # Check if task description is empty or still has placeholder
    if ! grep -A 2 "## Task Description" task.md | grep -v "^#" | grep -v "^<" | grep -v "^$" | grep -q "[a-zA-Z]"; then
        print_warning "task.md does not contain a task description!"
        echo
        echo -e "${YELLOW}The task specification has not been filled out.${NC}"
        echo -e "${YELLOW}Please edit task.md and specify your task before continuing.${NC}"
        echo
        echo -e "${BLUE}Quick tip:${NC} You can use a simple one-line task description like:"
        echo -e "  ${GREEN}Build a REST API for user management${NC}"
        echo -e "  ${GREEN}Research AI applications in healthcare and create a report${NC}"
        echo
        read -p "Do you want to continue without a task? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Please edit task.md first, then run this script again."
            exit 1
        fi
    fi
else
    print_error "task.md not found in current directory!"
    print_status "Please ensure you're in the correct project directory."
    exit 1
fi

# Check if claude is installed
if ! command -v claude &> /dev/null; then
    print_error "Claude Code CLI is not installed. Please install it first."
    exit 1
fi

# Clean up any previous process mode sessions
if [ -d "comm" ] && [ -f "comm/worker1.pid" ]; then
    print_warning "Previous process mode session detected."
    read -p "Clean up previous session? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Try to terminate any running processes
        for i in {1..4}; do
            if [ -f "comm/worker${i}.pid" ]; then
                PID=$(cat "comm/worker${i}.pid" 2>/dev/null)
                if [ ! -z "$PID" ] && ps -p $PID > /dev/null 2>&1; then
                    kill $PID 2>/dev/null || true
                fi
            fi
        done
        rm -rf comm logs
        print_success "Previous session cleaned up"
    fi
fi

print_status "Ready to start process mode execution"

# Display instructions
echo
echo -e "${BLUE}Instructions:${NC}"
echo -e "1. Claude Code will manage background worker processes"
echo -e "2. Progress will be written to log files in ${YELLOW}logs/${NC}"
echo -e "3. Status updates will appear in ${YELLOW}comm/${NC}"
echo -e "4. To execute your task, use: ${YELLOW}/task-process${NC}"
echo
echo -e "${BLUE}Process Mode Commands:${NC}"
echo -e "• Start task:        ${YELLOW}/task-process${NC}"
echo -e "• Check logs:        ${YELLOW}tail -f logs/worker*.log${NC}"
echo -e "• Monitor status:    ${YELLOW}watch 'tail comm/worker*_status.txt'${NC}"
echo -e "• Emergency stop:    ${YELLOW}pkill -f worker.*_launch.sh${NC}"
echo
echo -e "${BLUE}Differences from tmux mode:${NC}"
echo -e "• No visual panes - workers run in background"
echo -e "• Communication via files instead of tmux"
echo -e "• Better for remote/SSH sessions"
echo -e "• Can handle more workers if needed"
echo

print_success "Now you can use Claude Code with /task-process command"

# Launch Claude Code
claude