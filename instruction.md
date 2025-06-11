# Claude Code Multi-Instance Management Manual

## PROJECT CONFIGURATION

### System Configuration
- **Worker Panes**: 4
- **Task Specification File**: `task.md`
- **Output Directory**: `outputs/`
- **Worker Instructions Directory**: Project root (worker[1-4]_instructions.md)
- **Final Report Location**: `outputs/reports/final_report.md`

### Task Execution Rules
1. When asked to "follow instruction.md" or via `/task` command, act as MANAGER in the main pane
2. Read task specification from `task.md`
3. Create and manage 4 worker panes according to the task specification
4. Use `outputs/` directory for new creation tasks, existing project structure for modifications
5. Close worker panes automatically upon task completion unless specified otherwise

### Worker Communication Protocol
All workers must use this format for reports:
```bash
tmux send-keys -t $MAIN_PANE '[Worker{N}] Status: {message}' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter
```

### Output Guidelines
- **New Projects**: Save to `outputs/{category}/`
- **Existing Projects**: Follow project conventions
- **Unspecified**: Default to `outputs/{category}/`

Categories: development, research, content, reports, temp

## OPERATOR INSTRUCTIONS
**When asked to "follow instruction.md", you will act as the MANAGER in the main pane. Your role is to:**
1. **Read the task specification** from task.md
2. **Set up the worker panes** (4 Claude instances) 
3. **Distribute tasks** to worker panes based on the specification
4. **Monitor progress** and coordinate between workers
5. **Collect and integrate results** from all workers
6. **Generate the final deliverables**
7. **Close worker panes** and provide completion report when finished

**You are NOT a worker - you are the orchestrator and supervisor of the entire operation.**

## 1. Introduction

This manual is a guide for efficiently managing and operating multiple Claude Code instances using tmux.

## 2. Initial Setup

### 2.1 Creating tmux Pane Configuration

```bash
# Record current directory
WORK_DIR=$(pwd)

# Split into 5 panes (more stable method)
tmux split-window -h
tmux split-window -v
tmux select-pane -t 0
tmux split-window -v
tmux select-pane -t 2
tmux split-window -v

# Adjust layout evenly
tmux select-layout tiled
```

### 2.2 Confirming and Recording Pane IDs

```bash
# Confirm all pane IDs
tmux list-panes -F "#{pane_index}: %#{pane_id}"

# Save results to variables (example)
MAIN_PANE=%33
PANE1=%34
PANE2=%35
PANE3=%36
PANE4=%37
```

### 2.3 Starting Claude Code

```bash
# Alias setup (first time only)
alias cc="claude --dangerously-skip-permissions"

# Parallel startup in all panes (replace with actual pane IDs)
for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
    tmux send-keys -t $pane "cd '$WORK_DIR' && cc" && sleep 0.1 && tmux send-keys -t $pane Enter &
done
wait

# Startup verification (after 10 seconds wait)
sleep 10
for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
    echo "=== $pane status ==="
    tmux capture-pane -t $pane -p | tail -3
done
```

## 3. Task Management System

### 3.1 Task Assignment Templates

#### Basic Form
```bash
tmux send-keys -t $PANE1 "cd '$WORK_DIR' && You are pane1. [Task content]. After completion, report with tmux send-keys -t $MAIN_PANE '[pane1] Task completed' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter." && sleep 0.1 && tmux send-keys -t $PANE1 Enter
```

#### For Complex Tasks (including line breaks)
```bash
tmux send-keys -t $PANE1 "cd '$WORK_DIR' && \\
You are pane1. Please execute the following tasks: \\
1. [Task 1] \\
2. [Task 2] \\
3. [Task 3] \\
Please report progress at each step completion. \\
Reporting method: tmux send-keys -t $MAIN_PANE '[pane1] Progress: [content]' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter" && sleep 0.1 && tmux send-keys -t $PANE1 Enter
```

### 3.2 Parallel Task Execution

```bash
# Assign different tasks to each pane
tmux send-keys -t $PANE1 "You are pane1. Please handle data collection. After completion, report with tmux send-keys -t $MAIN_PANE '[pane1] Data collection completed' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter." && sleep 0.1 && tmux send-keys -t $PANE1 Enter & \
tmux send-keys -t $PANE2 "You are pane2. Please handle data analysis. After completion, report with tmux send-keys -t $MAIN_PANE '[pane2] Analysis completed' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter." && sleep 0.1 && tmux send-keys -t $PANE2 Enter & \
tmux send-keys -t $PANE3 "You are pane3. Please handle report creation. After completion, report with tmux send-keys -t $MAIN_PANE '[pane3] Report completed' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter." && sleep 0.1 && tmux send-keys -t $PANE3 Enter & \
wait
```

## 4. Communication System (Report, Contact, Consultation)

### ⚠️ IMPORTANT: Message Confirmation
**All messages sent via `tmux send-keys` MUST be confirmed with Enter to be delivered!**

```bash
# ❌ WRONG - Message will NOT be sent
tmux send-keys -t $MAIN_PANE "Message"

# ✅ CORRECT - Message will be sent
tmux send-keys -t $MAIN_PANE "Message" Enter

# ✅ ALSO CORRECT - With sleep for stability
tmux send-keys -t $MAIN_PANE "Message" && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter
```

### 4.1 Report Format

```bash
# Basic report
[pane_number] Status: Message

# Examples
[pane1] Completed: Data collection finished
[pane2] Error: File not found
[pane3] Progress: 50% complete, approximately 10 minutes remaining
[pane4] Consultation: May I change the approach?
```

### 4.2 Regular Reporting Mechanism

```bash
# For long-running tasks, incorporate regular reporting
tmux send-keys -t $PANE1 "You are pane1. Starting large-scale data processing. \\
Please report progress every 10 minutes: \\
tmux send-keys -t $MAIN_PANE '[pane1] Progress: XX% complete' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter" && sleep 0.1 && tmux send-keys -t $PANE1 Enter
```

## 5. Token Management

### 5.1 Usage Monitoring

```bash
# Check token usage for each pane
for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
    echo "=== Checking $pane ==="
    tmux send-keys -t $pane "ccusage" && sleep 0.1 && tmux send-keys -t $pane Enter
    sleep 2
    tmux capture-pane -t $pane -p | grep -A5 "Token"
done
```

### 5.2 Efficient Clear Strategy

```bash
# Conditional clear
check_and_clear() {
    local pane=$1
    local threshold=50000  # Token threshold
    
    # Check usage and determine if clear is needed
    tmux send-keys -t $pane "ccusage" && sleep 0.1 && tmux send-keys -t $pane Enter
    sleep 2
    
    # Clear if threshold exceeded
    tmux send-keys -t $pane "/clear" && sleep 0.1 && tmux send-keys -t $pane Enter
}

# Batch clear all panes (after task completion)
for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
    tmux send-keys -t $pane "/clear" && sleep 0.1 && tmux send-keys -t $pane Enter &
done
wait
```

## 6. Status Monitoring and Troubleshooting

### 6.1 Health Check

```bash
# Check status of all panes
health_check() {
    for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
        echo "=== $pane Health Check ==="
        
        # Check latest output
        local last_output=$(tmux capture-pane -t $pane -p | tail -5)
        
        # Responsiveness check
        tmux send-keys -t $pane "echo 'Health check OK'" && sleep 0.1 && tmux send-keys -t $pane Enter
        sleep 2
        
        # Error pattern detection
        if echo "$last_output" | grep -q "error\|Error\|ERROR"; then
            echo "WARNING: Error detected in $pane"
        fi
    done
}
```

### 6.2 Problem Resolution Procedures

```bash
# When a pane freezes
recover_pane() {
    local pane=$1
    
    # 1. Send Ctrl+C
    tmux send-keys -t $pane C-c
    sleep 1
    
    # 2. Clear command
    tmux send-keys -t $pane "/clear" && sleep 0.1 && tmux send-keys -t $pane Enter
    sleep 1
    
    # 3. Assign new task
    tmux send-keys -t $pane "echo 'Recovered and ready'" && sleep 0.1 && tmux send-keys -t $pane Enter
}
```

## 7. Advanced Coordination Patterns

### 7.1 Pipeline Processing

```bash
# Data processing pipeline
# Pane1: Data collection → Pane2: Preprocessing → Pane3: Analysis → Pane4: Report generation

# Step 1: Data collection
tmux send-keys -t $PANE1 "You are pane1. Please collect data and save to data.json. After completion, report with tmux send-keys -t $MAIN_PANE '[pane1] Data collection completed, ready for handoff to pane2' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter." && sleep 0.1 && tmux send-keys -t $PANE1 Enter

# After waiting for completion, proceed to Step 2
# (Execute after confirmation in main pane)
tmux send-keys -t $PANE2 "You are pane2. Please preprocess data.json and create processed_data.json..." && sleep 0.1 && tmux send-keys -t $PANE2 Enter
```

### 7.2 Collaborative Work

```bash
# Collaborative editing with multiple panes
# Give all panes access to the same file, edit different sections

tmux send-keys -t $PANE1 "You are pane1. Please create the Introduction section of report.md. Be careful not to conflict with other panes." && sleep 0.1 && tmux send-keys -t $PANE1 Enter & \
tmux send-keys -t $PANE2 "You are pane2. Please create the Methodology section of report.md." && sleep 0.1 && tmux send-keys -t $PANE2 Enter & \
tmux send-keys -t $PANE3 "You are pane3. Please create the Results section of report.md." && sleep 0.1 && tmux send-keys -t $PANE3 Enter & \
wait
```


## 9. Best Practices

### 9.1 Naming Conventions
- Always specify pane numbers explicitly
- Assign task IDs for trackability
- Include date/time and pane numbers in filenames

### 9.2 Error Handling
- Set timeouts for each task
- Automatic retry mechanisms on errors
- Prepare alternative plans in advance for failures

### 9.3 Performance Optimization
- Load balance heavy tasks
- Parallelize I/O-intensive tasks
- Execute CPU-intensive tasks sequentially

## 10. Common Problems and Solutions

### Q1: Pane Not Responding
```bash
# Force terminate and restart
tmux kill-pane -t $PANE1
tmux split-window -h
# Get new pane ID and reassign
```

### Q2: Out of Memory Error
```bash
# Clear all panes to free memory
for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
    tmux send-keys -t $pane "/clear" && sleep 0.1 && tmux send-keys -t $pane Enter
done
```

### Q3: Synchronization Issues
```bash
# Implement barrier synchronization
echo "Waiting for all panes to complete..."
while true; do
    # Check status of each pane
    completed=0
    for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
        if tmux capture-pane -t $pane -p | tail -1 | grep -q "completed"; then
            ((completed++))
        fi
    done
    
    if [ $completed -eq 4 ]; then
        echo "All panes completed!"
        break
    fi
    
    sleep 5
done
```

## 11. Security and Privacy

- Use `--dangerously-skip-permissions` flag only in development environments
- Process tasks containing sensitive information in a single pane
- Regular deletion of log files

---

## Task Execution Instructions for Operator

### Phase 1: Environment Setup

```bash
# 1. Save current directory
WORK_DIR=$(pwd)

# 2. Create 5-pane layout
tmux split-window -h
tmux split-window -v
tmux select-pane -t 0
tmux split-window -v
tmux select-pane -t 2
tmux split-window -v
tmux select-layout tiled

# 3. Get and save pane IDs
tmux list-panes -F "#{pane_index}: %#{pane_id}"
# Save the output as:
MAIN_PANE=%[YOUR_MAIN_PANE_ID]
PANE1=%[PANE1_ID]
PANE2=%[PANE2_ID]
PANE3=%[PANE3_ID]
PANE4=%[PANE4_ID]

# 4. Start Claude Code in all panes
alias cc="claude --dangerously-skip-permissions"
for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
    tmux send-keys -t $pane "cd '$WORK_DIR' && cc" && sleep 0.1 && tmux send-keys -t $pane Enter &
done
wait

# 5. Wait and verify startup (10 seconds)
sleep 10
for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
    echo "=== $pane status ==="
    tmux capture-pane -t $pane -p | tail -3
done

# 6. Create output directory structure (if needed)
# Check if this is a new creation task or working on existing project
if [[ ! -d "src" && ! -d "app" && ! -f "package.json" && ! -f "requirements.txt" ]]; then
    echo "Appears to be a new project. Creating output directory structure..."
    mkdir -p outputs/{development,research,content,reports,temp}
    echo "Created output directory structure:"
    ls -la outputs/
else
    echo "Existing project detected. Will use project's existing structure."
fi
```

**Output Directory Guidelines:**
- **New Creation Tasks**: Use the `outputs/` directory structure
- **Existing Projects**: Follow the project's existing conventions
- **Mixed Tasks**: Use `outputs/` for new deliverables, existing structure for modifications

```
outputs/              # For new creation tasks only
├── development/      # Code, APIs, databases, tests
├── research/         # Research findings, data, analysis
├── content/          # Articles, documentation, media
├── reports/          # Final reports, summaries, presentations
└── temp/            # Temporary files, work in progress
```

### Phase 2: Task Assignment Commands (Manager's Toolkit)

As the manager, you will assign tasks to worker panes. Always include clear instructions and reporting requirements.

#### ⚠️ Critical Communication Rule
**ALWAYS end tmux send-keys commands with Enter to confirm the message!**
- Without Enter, the message sits in the input buffer but is NOT executed
- Use `&& sleep 0.1 &&` between the message and Enter for stability
- This applies to ALL inter-pane communications

#### Manager's Task Assignment Philosophy
- Break down complex tasks into parallel workstreams
- Assign clear deliverables and deadlines to each worker
- Require regular progress reports
- Coordinate dependencies between workers
- Quality check all outputs before integration

#### Preparation: Create Worker Instructions
Before assigning tasks, create instruction files for each worker:

```bash
# Create worker instruction files based on the template
cp worker_instructions_template.md worker1_instructions.md
cp worker_instructions_template.md worker2_instructions.md
cp worker_instructions_template.md worker3_instructions.md
cp worker_instructions_template.md worker4_instructions.md

# Edit each file with specific instructions for that worker
# Or create them programmatically as the manager
```

**Benefits of Using Instruction Files:**
- No character limit in tmux commands
- Workers can re-read instructions if needed
- Clear documentation of what each worker was asked to do
- Easy to review and modify assignments
- Can include examples, templates, and detailed specifications

#### A. For Discussion/Brainstorming Tasks
```bash
# As manager, create instruction files then assign workers to read them
# First, create worker1_instructions.md with specific task details, then:
tmux send-keys -t $PANE1 "cd '$WORK_DIR' && Read worker1_instructions.md for your assignment. Begin immediately and follow all communication protocols specified in the file." && sleep 0.1 && tmux send-keys -t $PANE1 Enter

# Similarly for other workers:
tmux send-keys -t $PANE2 "cd '$WORK_DIR' && Read worker2_instructions.md for your assignment. Begin immediately and follow all communication protocols." && sleep 0.1 && tmux send-keys -t $PANE2 Enter

tmux send-keys -t $PANE3 "cd '$WORK_DIR' && Read worker3_instructions.md for your assignment. Begin immediately and follow all communication protocols." && sleep 0.1 && tmux send-keys -t $PANE3 Enter

tmux send-keys -t $PANE4 "cd '$WORK_DIR' && Read worker4_instructions.md for your assignment. Begin immediately and follow all communication protocols." && sleep 0.1 && tmux send-keys -t $PANE4 Enter
```

#### B. For Development Tasks
```bash
# Create detailed instruction files for each developer role, then:
tmux send-keys -t $PANE1 "cd '$WORK_DIR' && Read worker1_instructions.md for your Backend Developer assignment. Start immediately." && sleep 0.1 && tmux send-keys -t $PANE1 Enter

tmux send-keys -t $PANE2 "cd '$WORK_DIR' && Read worker2_instructions.md for your Frontend Developer assignment. Note dependencies on Worker 1." && sleep 0.1 && tmux send-keys -t $PANE2 Enter

tmux send-keys -t $PANE3 "cd '$WORK_DIR' && Read worker3_instructions.md for your Database Architect assignment. Coordinate with Worker 1 as specified." && sleep 0.1 && tmux send-keys -t $PANE3 Enter

tmux send-keys -t $PANE4 "cd '$WORK_DIR' && Read worker4_instructions.md for your QA Engineer assignment. Monitor other workers' outputs as instructed." && sleep 0.1 && tmux send-keys -t $PANE4 Enter
```

#### C. For Research Tasks
```bash
# Replace [RESEARCH_TOPIC], [SOURCE_TYPE], [DATA_TYPE] with actual values
tmux send-keys -t $PANE1 "cd '$WORK_DIR' && You are pane1. Research [RESEARCH_TOPIC] focusing on [ASPECT]. Find [NUMBER] sources. Save findings to research_pane1.md. Report: tmux send-keys -t $MAIN_PANE '[pane1] Found [NUMBER] relevant sources' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter" && sleep 0.1 && tmux send-keys -t $PANE1 Enter

tmux send-keys -t $PANE2 "cd '$WORK_DIR' && You are pane2. Collect data about [DATA_TYPE] from [SOURCES]. Save to data_pane2.json. Report: tmux send-keys -t $MAIN_PANE '[pane2] Collected [NUMBER] data points' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter" && sleep 0.1 && tmux send-keys -t $PANE2 Enter

# Continue for analysis and visualization panes...
```

#### D. For Content Creation Tasks
```bash
# Replace [CONTENT_TYPE], [TARGET_AUDIENCE], [WORD_COUNT] with actual values
tmux send-keys -t $PANE1 "cd '$WORK_DIR' && You are pane1. Research facts for [CONTENT_TYPE] about [TOPIC]. Verify [NUMBER] key facts. Save to facts_pane1.md. Report: tmux send-keys -t $MAIN_PANE '[pane1] Verified [NUMBER] facts' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter" && sleep 0.1 && tmux send-keys -t $PANE1 Enter

tmux send-keys -t $PANE2 "cd '$WORK_DIR' && You are pane2. Write [CONTENT_TYPE] about [TOPIC] for [TARGET_AUDIENCE]. Target [WORD_COUNT] words. Save to content_pane2.md. Report progress every 500 words: tmux send-keys -t $MAIN_PANE '[pane2] Progress: [WORDS] words written' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter" && sleep 0.1 && tmux send-keys -t $PANE2 Enter

# Continue for supporting materials and editing...
```

#### E. For Problem-Solving Tasks
```bash
# Replace [PROBLEM], [APPROACH], [CONSTRAINTS] with actual values
tmux send-keys -t $PANE1 "cd '$WORK_DIR' && You are pane1. Solve [PROBLEM] using [APPROACH_A]. Consider [CONSTRAINTS]. Save solution to solution_a.py. Report: tmux send-keys -t $MAIN_PANE '[pane1] Solution A implemented with complexity O([COMPLEXITY])' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter" && sleep 0.1 && tmux send-keys -t $PANE1 Enter

tmux send-keys -t $PANE2 "cd '$WORK_DIR' && You are pane2. Solve [PROBLEM] using [APPROACH_B]. Save to solution_b.py. Report: tmux send-keys -t $MAIN_PANE '[pane2] Solution B implemented with complexity O([COMPLEXITY])' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter" && sleep 0.1 && tmux send-keys -t $PANE2 Enter

# Continue for testing and optimization...
```

### Phase 3: Manager's Monitoring and Coordination Duties

As the manager, you have specific responsibilities beyond task assignment:

#### 3.1 Active Supervision
```bash
# Regularly check worker progress
check_worker_status() {
    echo "=== WORKER STATUS CHECK $(date) ==="
    for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
        echo "Checking $pane..."
        tmux send-keys -t $pane "Please report current status and any blockers" && sleep 0.1 && tmux send-keys -t $pane Enter
    done
}

# Monitor for stuck or idle workers
detect_idle_workers() {
    for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
        last_output=$(tmux capture-pane -t $pane -p | tail -10)
        # If no recent activity, prompt worker
        tmux send-keys -t $pane "Status update required. Are you blocked?" && sleep 0.1 && tmux send-keys -t $pane Enter
    done
}
```

#### 3.2 Quality Control
```bash
# Review deliverables from workers
review_output() {
    echo "=== QUALITY REVIEW ==="
    echo "1. Check if outputs meet requirements"
    echo "2. Verify consistency across worker outputs"
    echo "3. Identify gaps or missing elements"
    echo "4. Request revisions if needed"
}

# Send revision requests
request_revision() {
    tmux send-keys -t $[WORKER_PANE] "Revision needed: [SPECIFIC_ISSUE]. Please update and report back." && sleep 0.1 && tmux send-keys -t $[WORKER_PANE] Enter
}
```

#### 3.3 Resource Management
```bash
# Monitor and manage token usage
manage_resources() {
    for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
        tmux send-keys -t $pane "ccusage" && sleep 0.1 && tmux send-keys -t $pane Enter
        sleep 2
        # If approaching limit, instruct worker to summarize and clear
        tmux send-keys -t $pane "Approaching token limit. Please save your work and prepare to clear context." Enter
    done
}
```

#### 3.4 Coordination Patterns
```bash
# Manage dependencies between workers
coordinate_dependencies() {
    # Example: Frontend waits for Backend API
    echo "Worker 2: Hold on API integration until Worker 1 completes endpoint definitions"
    
    # When Worker 1 reports completion
    tmux send-keys -t $PANE2 "Worker 1 has completed API endpoints. You may now proceed with integration." Enter
}

# Facilitate information sharing
share_information() {
    # When one worker produces something others need
    tmux send-keys -t $PANE2 "Worker 1 has created API docs at api_docs.md. Please review for your UI implementation." Enter
    tmux send-keys -t $PANE4 "Workers 1-3 have completed initial implementations. Begin integration testing." Enter
}
```

### Phase 4: Manager's Results Integration and Delivery

As manager, you are responsible for collecting, integrating, and delivering the final results.

#### 4.1 Results Collection
```bash
# Instruct workers to finalize their outputs
finalize_outputs() {
    echo "=== FINALIZING OUTPUTS ==="
    for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
        tmux send-keys -t $pane "Please finalize your deliverables and provide a summary of what you've created." && sleep 0.1 && tmux send-keys -t $pane Enter
    done
}

# Collect all outputs
collect_results() {
    mkdir -p results
    
    # Get summaries from each worker
    for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
        tmux send-keys -t $pane "List all files you've created with brief descriptions" && sleep 0.1 && tmux send-keys -t $pane Enter
    done
    
    # Capture outputs
    sleep 5  # Give workers time to respond
    for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
        tmux capture-pane -t $pane -p > "results/${pane}_summary.txt"
    done
}
```

#### 4.2 Integration and Synthesis
```bash
# Manager's synthesis responsibilities
synthesize_results() {
    echo "=== MANAGER'S SYNTHESIS PHASE ==="
    echo "1. Review all worker outputs"
    echo "2. Identify overlaps and gaps"
    echo "3. Resolve any conflicts"
    echo "4. Create unified deliverable"
    echo "5. Add executive summary"
}
```

#### 4.3 Final Report Generation
```bash
# Generate comprehensive final report
generate_final_report() {
    cat > final_report.md << EOF
# Task Execution Report

## Executive Summary
[MANAGER'S HIGH-LEVEL SUMMARY OF ACHIEVEMENTS]

## Task: [TASK_DESCRIPTION]
## Date: $(date)
## Manager: Main Pane
## Workers: 4 Claude Instances

### Manager's Assessment
[YOUR EVALUATION OF THE TASK EXECUTION]

### Worker 1 Deliverables
[SUMMARY OF WORKER 1'S CONTRIBUTIONS]
- Files created: [LIST]
- Key achievements: [LIST]

### Worker 2 Deliverables
[SUMMARY OF WORKER 2'S CONTRIBUTIONS]
- Files created: [LIST]
- Key achievements: [LIST]

### Worker 3 Deliverables
[SUMMARY OF WORKER 3'S CONTRIBUTIONS]
- Files created: [LIST]
- Key achievements: [LIST]

### Worker 4 Deliverables
[SUMMARY OF WORKER 4'S CONTRIBUTIONS]
- Files created: [LIST]
- Key achievements: [LIST]

### Integrated Solution
[MANAGER'S SYNTHESIS OF ALL WORK]

### Quality Metrics
- Task completion: [PERCENTAGE]
- Quality assessment: [RATING]
- Timeline adherence: [STATUS]

### Recommendations
[MANAGER'S RECOMMENDATIONS FOR FUTURE IMPROVEMENTS]

### All Files Created
$(find outputs -type f -name "*.*" | sort)

### Directory Structure
$(tree outputs 2>/dev/null || find outputs -type d | sort | sed 's|^|  |')
EOF

    # Save the report in the reports directory
    mv final_report.md outputs/reports/
    echo "Final report saved to: outputs/reports/final_report.md"
}
```

### Phase 5: Task Completion and Cleanup

```bash
# Final cleanup and completion
complete_task() {
    echo "=== TASK COMPLETION SEQUENCE ==="
    
    # 1. Save all work
    echo "Ensuring all work is saved..."
    for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
        tmux send-keys -t $pane "Please save any unsaved work immediately." && sleep 0.1 && tmux send-keys -t $pane Enter
    done
    sleep 5
    
    # 2. Thank workers
    echo "Thanking workers..."
    for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
        tmux send-keys -t $pane "Thank you for your contributions. This session will now close." && sleep 0.1 && tmux send-keys -t $pane Enter
    done
    sleep 2
    
    # 3. Close worker panes
    echo "Closing worker panes..."
    for pane in $PANE4 $PANE3 $PANE2 $PANE1; do
        tmux kill-pane -t $pane
    done
    
    # 4. Final report in main pane
    echo "==================================="
    echo "TASK COMPLETED SUCCESSFULLY"
    echo "==================================="
    echo "Date: $(date)"
    echo "Duration: [Calculate from start time]"
    echo ""
    echo "Summary:"
    echo "- All worker panes have been closed"
    echo "- Final report saved to: outputs/reports/final_report.md"
    echo "- All deliverables are in the outputs/ directory"
    echo ""
    echo "The manager (main pane) remains active for any follow-up tasks."
}

# Alternative: Just clear panes without closing
cleanup_panes() {
    for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
        tmux send-keys -t $pane "/clear" && sleep 0.1 && tmux send-keys -t $pane Enter &
    done
    wait
    echo "All panes cleared (but still active)"
}
```

### Quick Reference - Task Template

```bash
# General task assignment template
tmux send-keys -t $[PANE_VAR] "cd '$WORK_DIR' && \\
You are [PANE_NAME]. \\
Task: [SPECIFIC_TASK_DESCRIPTION] \\
Requirements: [SPECIFIC_REQUIREMENTS] \\
Output: Save to [OUTPUT_FILENAME] \\
Progress reporting: tmux send-keys -t $MAIN_PANE '[PANE_NAME] Status: [STATUS_MESSAGE]' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter \\
Completion report: tmux send-keys -t $MAIN_PANE '[PANE_NAME] Completed: [COMPLETION_DETAILS]' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter" && sleep 0.1 && tmux send-keys -t $[PANE_VAR] Enter
```


## MANAGER EXECUTION CHECKLIST

As the manager in the main pane, follow this workflow:

### Initial Setup
1. [ ] Read task specification from task.md
2. [ ] Analyze task complexity and plan worker allocation
3. [ ] Determine if this is a new creation task or modification of existing project
4. [ ] Set up the tmux environment with 4 worker panes (Phase 1)
5. [ ] Create output directory structure if needed (for new creation tasks)

### Task Distribution
6. [ ] Break down the main task into 4 parallel workstreams
7. [ ] Assign specific roles to each worker (Developer, Analyst, etc.)
8. [ ] Create worker instruction files with output location guidance
9. [ ] Send detailed task assignments with clear deliverables
10. [ ] Set reporting requirements and milestones

### Active Management
11. [ ] Monitor worker progress continuously
12. [ ] Respond to worker questions and blockers
13. [ ] Coordinate dependencies between workers
14. [ ] Perform quality checks on interim deliverables
15. [ ] Redirect workers as needed based on progress

### Results Integration
16. [ ] Collect final outputs from all workers
17. [ ] Review and synthesize worker deliverables
18. [ ] Resolve any conflicts or inconsistencies
19. [ ] Create integrated final deliverable
20. [ ] Generate comprehensive final report

### Task Completion
21. [ ] Ensure all work is saved
22. [ ] Thank workers for their contributions
23. [ ] Execute `complete_task()` to close worker panes
24. [ ] Display final completion report
25. [ ] Remain available in main pane for follow-up
