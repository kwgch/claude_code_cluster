#!/bin/bash

# Claude Code Task Management System Launcher
# This script sets up tmux and launches Claude Code for multi-instance task execution

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
echo -e "${GREEN}║           Claude Code Task Management System               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo

# Check if instruction.md exists and has default values
if [ -f "instruction.md" ]; then
    # Check for default placeholder values in instruction.md
    if grep -q "\[YOUR_TASK_DESCRIPTION\]" instruction.md; then
        print_warning "instruction.md still contains default placeholder values!"
        echo
        echo -e "${YELLOW}The USER TASK SPECIFICATION section has not been filled out.${NC}"
        echo -e "${YELLOW}Please edit instruction.md and specify your task before continuing.${NC}"
        echo
        echo -e "${BLUE}Quick tip:${NC} You can use a simple one-line task description like:"
        echo -e "  ${GREEN}Build a REST API for user management${NC}"
        echo -e "  ${GREEN}Research AI applications in healthcare and create a report${NC}"
        echo
        read -p "Do you want to continue with the default template? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Please edit instruction.md first, then run this script again."
            exit 1
        fi
    fi
else
    print_error "instruction.md not found in current directory!"
    print_status "Please ensure you're in the correct project directory."
    exit 1
fi

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    print_error "tmux is not installed. Please install tmux first."
    exit 1
fi

# Check if claude is installed
if ! command -v claude &> /dev/null; then
    print_error "Claude Code CLI is not installed. Please install it first."
    exit 1
fi

# Check if we're already in a tmux session
if [ -n "$TMUX" ]; then
    print_warning "Already in a tmux session. Please exit first or run this script outside tmux."
    exit 1
fi

# Session name (can be customized)
SESSION_NAME="claude_multi"

# Check if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    print_warning "Session '$SESSION_NAME' already exists."
    read -p "Do you want to attach to existing session? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        tmux attach-session -t "$SESSION_NAME"
        exit 0
    else
        read -p "Do you want to kill the existing session and create a new one? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            tmux kill-session -t "$SESSION_NAME"
            print_success "Killed existing session"
        else
            print_status "Exiting..."
            exit 0
        fi
    fi
fi

print_status "Creating new tmux session: $SESSION_NAME"

# Create new session with Claude Code
tmux new-session -d -s "$SESSION_NAME" -n "main" 'claude --dangerously-skip-permissions'

# Give the first instance time to start
sleep 1

print_success "Created tmux session '$SESSION_NAME'"
print_status "Starting Claude Code in main window..."

# Display instructions
echo
echo -e "${BLUE}Instructions:${NC}"
echo -e "1. The tmux session '$SESSION_NAME' has been created"
echo -e "2. Claude Code is running with --dangerously-skip-permissions"
echo -e "3. To execute your task, type: ${YELLOW}follow instruction.md${NC}"
echo
echo -e "${BLUE}Quick Commands:${NC}"
echo -e "• View all panes:    ${YELLOW}Ctrl+b q${NC}"
echo -e "• Switch panes:      ${YELLOW}Ctrl+b [arrow keys]${NC}"
echo -e "• Detach session:    ${YELLOW}Ctrl+b d${NC}"
echo -e "• Emergency stop:    ${YELLOW}tmux kill-server${NC} (kills ALL tmux sessions)"
echo
echo -e "${BLUE}Task Setup:${NC}"
echo -e "• Edit ${YELLOW}instruction.md${NC} to specify your task before starting"
echo -e "• Or use the simple format: just write a task description"
echo

read -p "Press Enter to attach to the session..."

# Attach to the session
tmux attach-session -t "$SESSION_NAME"