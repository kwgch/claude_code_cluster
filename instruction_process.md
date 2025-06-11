# Claude Code Multi-Instance Process Mode Manual

## PROJECT CONFIGURATION

### System Configuration
- **Worker Processes**: 4
- **Task Specification File**: `task.md`
- **Output Directory**: `outputs/`
- **Worker Instructions Directory**: Project root (worker[1-4]_instructions.md)
- **Worker Logs Directory**: `logs/`
- **Communication Directory**: `comm/`
- **Final Report Location**: `outputs/reports/final_report.md`

### Process Mode Rules
1. When asked via `/task-process` command, act as MANAGER
2. Read task specification from `task.md`
3. Launch 4 worker processes in background
4. Monitor progress through log files and communication files
5. Use file-based communication instead of tmux
6. Terminate worker processes upon task completion

### Worker Communication Protocol
Workers write status updates to communication files:
```
echo "[Worker1] Status: Starting backend development" >> comm/worker1_status.txt
echo "[Worker1] Progress: API routes defined" >> comm/worker1_status.txt
echo "[Worker1] COMPLETED: Backend API ready" >> comm/worker1_status.txt
```

### Output Guidelines
Same as tmux mode - outputs go to appropriate directories.

## OPERATOR INSTRUCTIONS
**When asked via `/task-process` command, you will act as the MANAGER. Your role is to:**
1. **Read the task specification** from task.md
2. **Launch worker processes** (4 Claude instances in background)
3. **Create worker instruction files** with specific tasks
4. **Monitor progress** through log and status files
5. **Collect and integrate results** from all workers
6. **Generate the final deliverables**
7. **Terminate worker processes** and provide completion report

**You are managing background processes, not interactive panes.**

## Phase 1: Process Environment Setup

```bash
# 1. Save current directory
WORK_DIR=$(pwd)

# 2. Create required directories
mkdir -p logs comm outputs/{development,research,content,reports,temp}

# 3. Clear previous session files
rm -f logs/worker*.log comm/worker*_status.txt

# 4. Initialize Git workflow (if in repository)
if git rev-parse --git-dir > /dev/null 2>&1; then
    ORIGINAL_BRANCH=$(git branch --show-current)
    WORK_BRANCH="work/task-$(date +%Y%m%d-%H%M%S)"
    git checkout -b "$WORK_BRANCH"
    git add task.md 2>/dev/null || true
    git commit -m "Start task: $(head -n 20 task.md | grep -A 2 'Task Description' | tail -n +2 | tr '\n' ' ' | cut -c 1-50)..." 2>/dev/null || true
fi

# 5. Launch worker processes
for i in {1..4}; do
    echo "Starting Worker $i..."
    
    # Create worker launch script
    cat > "worker${i}_launch.sh" << EOF
#!/bin/bash
cd '$WORK_DIR'

# Read instructions
if [ -f "worker${i}_instructions.md" ]; then
    claude "Please read worker${i}_instructions.md and execute the task. Write all status updates to comm/worker${i}_status.txt. Save your work regularly."
else
    echo "No instructions found for Worker $i"
fi
EOF
    
    chmod +x "worker${i}_launch.sh"
    
    # Launch in background with logging
    nohup ./worker${i}_launch.sh > logs/worker${i}.log 2>&1 &
    echo $! > "comm/worker${i}.pid"
    
    sleep 2  # Stagger launches
done

echo "All worker processes launched"
```

## Phase 2: Task Assignment

Same as tmux mode - create worker[1-4]_instructions.md files, but modify communication instructions:

```markdown
## Communication Protocol
- Write status updates to: `comm/worker[N]_status.txt`
- Format: `echo "[Worker[N]] Status: Your message" >> comm/worker[N]_status.txt`
- Report progress every 5-10 minutes
- Mark completion with: `echo "[Worker[N]] COMPLETED: Summary" >> comm/worker[N]_status.txt`
```

## Phase 3: Process Monitoring

```bash
# Monitor all worker processes
monitor_workers() {
    while true; do
        clear
        echo "=== WORKER PROCESS MONITOR ==="
        echo "Time: $(date)"
        echo ""
        
        # Check process status
        for i in {1..4}; do
            if [ -f "comm/worker${i}.pid" ]; then
                PID=$(cat "comm/worker${i}.pid")
                if ps -p $PID > /dev/null; then
                    echo "Worker $i: RUNNING (PID: $PID)"
                else
                    echo "Worker $i: STOPPED"
                fi
            fi
        done
        
        echo ""
        echo "=== RECENT STATUS UPDATES ==="
        
        # Show recent status from each worker
        for i in {1..4}; do
            echo "--- Worker $i ---"
            if [ -f "comm/worker${i}_status.txt" ]; then
                tail -3 "comm/worker${i}_status.txt"
            else
                echo "No status yet"
            fi
            echo ""
        done
        
        sleep 10
    done
}

# Check for completion
check_completion() {
    local completed=0
    for i in {1..4}; do
        if [ -f "comm/worker${i}_status.txt" ]; then
            if grep -q "COMPLETED:" "comm/worker${i}_status.txt"; then
                ((completed++))
            fi
        fi
    done
    
    if [ $completed -eq 4 ]; then
        echo "All workers completed!"
        return 0
    else
        return 1
    fi
}

# Git progress management (same as tmux mode)
milestone_commit() {
    local milestone="$1"
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git add -A
        git commit -m "Milestone: $milestone" || true
    fi
}
```

## Phase 4: Results Collection

```bash
# Same as tmux mode, but check logs directory
collect_results() {
    mkdir -p results
    
    # Copy worker logs
    cp logs/worker*.log results/
    
    # Copy status files
    cp comm/worker*_status.txt results/
    
    # List created files
    echo "=== Created Files ==="
    find outputs -type f -name "*.*" | sort
}
```

## Phase 5: Process Cleanup

```bash
complete_task() {
    echo "=== TASK COMPLETION SEQUENCE ==="
    
    # 1. Signal workers to finish
    for i in {1..4}; do
        echo "[Manager] Please complete and save all work" >> "comm/worker${i}_status.txt"
    done
    
    sleep 10  # Give time to finish
    
    # 2. Terminate worker processes
    echo "Terminating worker processes..."
    for i in {1..4}; do
        if [ -f "comm/worker${i}.pid" ]; then
            PID=$(cat "comm/worker${i}.pid")
            if ps -p $PID > /dev/null; then
                kill $PID 2>/dev/null || true
                echo "Terminated Worker $i (PID: $PID)"
            fi
            rm -f "comm/worker${i}.pid"
        fi
    done
    
    # 3. Clean up temporary files
    rm -f worker*_launch.sh
    rm -f worker*_instructions.md
    
    # 4. Final git commit
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git add -A
        git commit -m "Complete task: $(head -n 20 task.md | grep -A 2 'Task Description' | tail -n +2 | tr '\n' ' ' | cut -c 1-50)..." || true
        
        echo ""
        echo "Git Summary:"
        echo "- Work branch: $(git branch --show-current)"
        echo "- Commits made: $(git rev-list --count $ORIGINAL_BRANCH..HEAD)"
        echo "- Files changed: $(git diff --name-only $ORIGINAL_BRANCH..HEAD | wc -l)"
    fi
    
    # 5. Final report
    echo ""
    echo "==================================="
    echo "TASK COMPLETED SUCCESSFULLY"
    echo "==================================="
    echo "Date: $(date)"
    echo ""
    echo "Summary:"
    echo "- All worker processes terminated"
    echo "- Logs saved in: logs/"
    echo "- Status files saved in: comm/"
    echo "- Outputs saved in: outputs/"
    echo ""
    echo "Process mode execution complete."
}
```

## MANAGER EXECUTION CHECKLIST

### Initial Setup
1. [ ] Read task specification from task.md
2. [ ] Analyze task complexity and plan worker allocation
3. [ ] Create necessary directories (logs/, comm/)
4. [ ] Initialize git workflow if applicable
5. [ ] Launch 4 worker processes in background

### Task Distribution
6. [ ] Break down the main task into 4 parallel workstreams
7. [ ] Create worker instruction files with file-based communication
8. [ ] Ensure workers understand output locations
9. [ ] Set clear deliverables and milestones

### Active Management
10. [ ] Monitor worker processes and status files
11. [ ] Check logs for errors or issues
12. [ ] Commit progress at major milestones
13. [ ] Watch for completion markers
14. [ ] Handle any worker process failures

### Results Integration
15. [ ] Verify all workers have completed
16. [ ] Collect outputs from all workers
17. [ ] Review logs for any issues
18. [ ] Create integrated final deliverable
19. [ ] Generate comprehensive final report

### Task Completion
20. [ ] Ensure all work is saved
21. [ ] Terminate all worker processes
22. [ ] Clean up temporary files
23. [ ] Create final git commit
24. [ ] Provide completion summary