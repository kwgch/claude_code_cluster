# Claude Code Multi-Instance Process Mode Manual

## PROJECT CONFIGURATION

### System Configuration
- **Worker Processes**: Dynamic (auto-determined based on task and system)
- **Default Workers**: 4 (if not specified)
- **Maximum Workers**: Based on system resources
- **Task Specification File**: `task.md`
- **Output Directory**: `outputs/`
- **Worker Instructions Directory**: Project root (worker[N]_instructions.md)
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

## Phase 1: Dynamic Worker Determination and Environment Setup

```bash
# 1. Save current directory
WORK_DIR=$(pwd)

# 2. Analyze system resources
analyze_system_resources() {
    # Get CPU cores
    CPU_CORES=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    
    # Get available memory in GB
    if command -v free >/dev/null 2>&1; then
        MEM_GB=$(free -g | awk '/^Mem:/{print $7}')
    elif command -v vm_stat >/dev/null 2>&1; then
        MEM_GB=$(($(vm_stat | awk '/Pages free:/{print $3}' | sed 's/\.//')*4096/1024/1024/1024))
    else
        MEM_GB=8  # Default assumption
    fi
    
    # Check system load
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    echo "System Resources:"
    echo "- CPU cores: $CPU_CORES"
    echo "- Available memory: ${MEM_GB}GB"
    echo "- Current load: $LOAD_AVG"
}

# 3. Analyze task complexity
analyze_task_complexity() {
    # Read task description
    TASK_DESC=$(grep -A 10 "## Task Description" task.md | tail -n +2)
    
    # Estimate complexity based on keywords
    COMPLEXITY_SCORE=0
    
    # Development indicators
    if echo "$TASK_DESC" | grep -qi "full.stack\|backend.*frontend\|microservice\|distributed"; then
        COMPLEXITY_SCORE=$((COMPLEXITY_SCORE + 3))
    fi
    
    # Research indicators
    if echo "$TASK_DESC" | grep -qi "research\|analyze\|investigate\|compare.*multiple"; then
        COMPLEXITY_SCORE=$((COMPLEXITY_SCORE + 2))
    fi
    
    # Scale indicators
    if echo "$TASK_DESC" | grep -qi "large.scale\|enterprise\|production\|comprehensive"; then
        COMPLEXITY_SCORE=$((COMPLEXITY_SCORE + 2))
    fi
    
    # Parallel work indicators
    if echo "$TASK_DESC" | grep -qi "parallel\|simultaneous\|concurrent\|multiple.*components"; then
        COMPLEXITY_SCORE=$((COMPLEXITY_SCORE + 3))
    fi
    
    echo "Task Complexity Score: $COMPLEXITY_SCORE"
}

# 4. Determine optimal worker count
determine_worker_count() {
    analyze_system_resources
    analyze_task_complexity
    
    # Base calculation
    MAX_BY_CPU=$((CPU_CORES * 2))  # Can oversubscribe CPU
    MAX_BY_MEM=$((MEM_GB / 2))      # Assume 2GB per Claude instance
    
    # Task-based recommendation
    if [ $COMPLEXITY_SCORE -le 2 ]; then
        TASK_WORKERS=2
    elif [ $COMPLEXITY_SCORE -le 5 ]; then
        TASK_WORKERS=4
    elif [ $COMPLEXITY_SCORE -le 8 ]; then
        TASK_WORKERS=6
    else
        TASK_WORKERS=8
    fi
    
    # Final decision (minimum of all constraints)
    WORKER_COUNT=$TASK_WORKERS
    [ $WORKER_COUNT -gt $MAX_BY_CPU ] && WORKER_COUNT=$MAX_BY_CPU
    [ $WORKER_COUNT -gt $MAX_BY_MEM ] && WORKER_COUNT=$MAX_BY_MEM
    [ $WORKER_COUNT -lt 2 ] && WORKER_COUNT=2  # Minimum 2 workers
    
    echo ""
    echo "Worker Count Decision:"
    echo "- Task suggests: $TASK_WORKERS workers"
    echo "- CPU limit: $MAX_BY_CPU workers"
    echo "- Memory limit: $MAX_BY_MEM workers"
    echo "- Final decision: $WORKER_COUNT workers"
}

# 5. Setup environment with dynamic workers
determine_worker_count

# Create required directories
mkdir -p logs comm outputs/{development,research,content,reports,temp}

# Clear previous session files
rm -f logs/worker*.log comm/worker*_status.txt

# Initialize Git workflow (if in repository)
if git rev-parse --git-dir > /dev/null 2>&1; then
    ORIGINAL_BRANCH=$(git branch --show-current)
    WORK_BRANCH="work/task-$(date +%Y%m%d-%H%M%S)"
    git checkout -b "$WORK_BRANCH"
    git add task.md 2>/dev/null || true
    git commit -m "Start task: $(head -n 20 task.md | grep -A 2 'Task Description' | tail -n +2 | tr '\n' ' ' | cut -c 1-50)..." 2>/dev/null || true
fi

# 6. Launch worker processes
echo ""
echo "Launching $WORKER_COUNT worker processes..."

for i in $(seq 1 $WORKER_COUNT); do
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

echo "All $WORKER_COUNT worker processes launched"

# Save worker count for later phases
echo $WORKER_COUNT > comm/worker_count.txt
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
# Get worker count from saved file
WORKER_COUNT=$(cat comm/worker_count.txt 2>/dev/null || echo 4)

# Monitor all worker processes
monitor_workers() {
    while true; do
        clear
        echo "=== WORKER PROCESS MONITOR ==="
        echo "Time: $(date)"
        echo "Active Workers: $WORKER_COUNT"
        echo ""
        
        # Check process status
        for i in $(seq 1 $WORKER_COUNT); do
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
        for i in $(seq 1 $WORKER_COUNT); do
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
    local worker_count=$(cat comm/worker_count.txt 2>/dev/null || echo 4)
    
    for i in $(seq 1 $worker_count); do
        if [ -f "comm/worker${i}_status.txt" ]; then
            if grep -q "COMPLETED:" "comm/worker${i}_status.txt"; then
                ((completed++))
            fi
        fi
    done
    
    if [ $completed -eq $worker_count ]; then
        echo "All $worker_count workers completed!"
        return 0
    else
        return 1
    fi
}

# Dynamic worker scaling (can add more workers if needed)
add_worker() {
    local current_count=$(cat comm/worker_count.txt)
    local new_worker_id=$((current_count + 1))
    
    echo "Adding Worker $new_worker_id..."
    
    # Create and launch new worker
    cat > "worker${new_worker_id}_launch.sh" << EOF
#!/bin/bash
cd '$WORK_DIR'

if [ -f "worker${new_worker_id}_instructions.md" ]; then
    claude "Please read worker${new_worker_id}_instructions.md and execute the task. Write all status updates to comm/worker${new_worker_id}_status.txt. Save your work regularly."
else
    echo "No instructions found for Worker $new_worker_id"
fi
EOF
    
    chmod +x "worker${new_worker_id}_launch.sh"
    nohup ./worker${new_worker_id}_launch.sh > logs/worker${new_worker_id}.log 2>&1 &
    echo $! > "comm/worker${new_worker_id}.pid"
    
    # Update worker count
    echo $new_worker_id > comm/worker_count.txt
    echo "Worker $new_worker_id added successfully"
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
    
    # Get final worker count
    WORKER_COUNT=$(cat comm/worker_count.txt 2>/dev/null || echo 4)
    echo "Total workers used: $WORKER_COUNT"
    
    # 1. Signal workers to finish
    for i in $(seq 1 $WORKER_COUNT); do
        echo "[Manager] Please complete and save all work" >> "comm/worker${i}_status.txt"
    done
    
    sleep 10  # Give time to finish
    
    # 2. Terminate worker processes
    echo "Terminating $WORKER_COUNT worker processes..."
    for i in $(seq 1 $WORKER_COUNT); do
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