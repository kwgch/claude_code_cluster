# Claude Code Multi-Instance Management Manual

## OPERATOR INSTRUCTIONS
**When asked to "follow instruction.md", immediately proceed to the USER TASK SPECIFICATION section at the bottom of this file and execute the specified task using the tmux multi-instance system described in this manual.**

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
```

### Phase 2: Task Assignment Commands

#### A. For Discussion/Brainstorming Tasks
```bash
# Replace [TOPIC], [PERSPECTIVE], [QUESTION] with actual values
tmux send-keys -t $PANE1 "cd '$WORK_DIR' && You are pane1. Please discuss [TOPIC] from [PERSPECTIVE]. After providing key insights, report with: tmux send-keys -t $MAIN_PANE '[pane1] Key insight: [YOUR_INSIGHT]' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter" && sleep 0.1 && tmux send-keys -t $PANE1 Enter

tmux send-keys -t $PANE2 "cd '$WORK_DIR' && You are pane2. Please analyze [TOPIC] focusing on [SPECIFIC_ASPECT]. Report findings with: tmux send-keys -t $MAIN_PANE '[pane2] Finding: [YOUR_FINDING]' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter" && sleep 0.1 && tmux send-keys -t $PANE2 Enter

# Continue for PANE3 and PANE4...
```

#### B. For Development Tasks
```bash
# Replace [PROJECT_NAME], [FEATURE], [COMPONENT] with actual values
tmux send-keys -t $PANE1 "cd '$WORK_DIR' && You are pane1. Create the backend API for [FEATURE]. Use [FRAMEWORK]. Save to [FILENAME]. Report completion: tmux send-keys -t $MAIN_PANE '[pane1] Backend API created: [FILENAME]' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter" && sleep 0.1 && tmux send-keys -t $PANE1 Enter

tmux send-keys -t $PANE2 "cd '$WORK_DIR' && You are pane2. Implement frontend UI for [FEATURE]. Use [FRAMEWORK]. Save to [FILENAME]. Report: tmux send-keys -t $MAIN_PANE '[pane2] UI component created: [FILENAME]' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter" && sleep 0.1 && tmux send-keys -t $PANE2 Enter

tmux send-keys -t $PANE3 "cd '$WORK_DIR' && You are pane3. Design database schema for [FEATURE]. Include [REQUIREMENTS]. Save to [FILENAME]. Report: tmux send-keys -t $MAIN_PANE '[pane3] Schema created: [FILENAME]' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter" && sleep 0.1 && tmux send-keys -t $PANE3 Enter

tmux send-keys -t $PANE4 "cd '$WORK_DIR' && You are pane4. Write tests for [COMPONENT]. Cover [TEST_SCENARIOS]. Save to [FILENAME]. Report: tmux send-keys -t $MAIN_PANE '[pane4] Tests created: [FILENAME]' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter" && sleep 0.1 && tmux send-keys -t $PANE4 Enter
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

### Phase 3: Monitoring and Coordination

```bash
# Monitor all panes continuously
watch_panes() {
    while true; do
        clear
        echo "=== PANE STATUS MONITOR ==="
        for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
            echo "--- $pane ---"
            tmux capture-pane -t $pane -p | tail -5
            echo ""
        done
        sleep 5
    done
}

# Check token usage periodically
check_tokens() {
    for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
        echo "Checking $pane tokens..."
        tmux send-keys -t $pane "ccusage" && sleep 0.1 && tmux send-keys -t $pane Enter
        sleep 2
    done
}

# Coordinate dependent tasks
coordinate_pipeline() {
    # Wait for pane1 to complete
    echo "Waiting for pane1..."
    while ! tmux capture-pane -t $MAIN_PANE -p | grep -q "\[pane1\].*completed"; do
        sleep 5
    done
    
    # Start pane2 task that depends on pane1
    tmux send-keys -t $PANE2 "[DEPENDENT_TASK_COMMAND]" && sleep 0.1 && tmux send-keys -t $PANE2 Enter
}
```

### Phase 4: Results Collection

```bash
# Collect all outputs
collect_results() {
    mkdir -p results
    
    # Capture final outputs from each pane
    for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
        tmux capture-pane -t $pane -p > "results/${pane}_output.txt"
    done
    
    # List all created files
    echo "=== Created Files ==="
    ls -la | grep -E "\.(md|py|js|json|txt)$"
}

# Generate final report
generate_report() {
    cat > final_report.md << EOF
# Task Execution Report

## Task: [TASK_DESCRIPTION]
## Date: $(date)

### Pane 1 Results
[PANE1_SUMMARY]

### Pane 2 Results
[PANE2_SUMMARY]

### Pane 3 Results
[PANE3_SUMMARY]

### Pane 4 Results
[PANE4_SUMMARY]

### Integrated Results
[INTEGRATED_SUMMARY]

### Files Created
$(ls -la | grep -E "\.(md|py|js|json|txt)$")
EOF
}
```

### Phase 5: Cleanup

```bash
# Clear all panes
cleanup_panes() {
    for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
        tmux send-keys -t $pane "/clear" && sleep 0.1 && tmux send-keys -t $pane Enter &
    done
    wait
    echo "All panes cleared"
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

---

## USER TASK SPECIFICATION

### Task Type
<!-- OPTIONAL: Select one: development / research / content / problem-solving / discussion -->
<!-- Leave blank and Claude will infer from your task description -->
[TASK_TYPE]

### Task Description
<!-- REQUIRED: Describe what you want to accomplish -->
<!-- This can be as simple as one sentence or as detailed as needed -->
[YOUR_TASK_DESCRIPTION]

### Specific Requirements
<!-- OPTIONAL: List any specific requirements, constraints, or preferences -->
1. [REQUIREMENT_1]
2. [REQUIREMENT_2]
3. [REQUIREMENT_3]

### Expected Outputs
<!-- OPTIONAL: Describe the deliverables you expect -->
1. [OUTPUT_1]
2. [OUTPUT_2]
3. [OUTPUT_3]

### Task Distribution Plan
<!-- OPTIONAL: Suggest how to divide work among panes, or leave blank for automatic distribution -->
- Pane 1: [PANE1_TASK]
- Pane 2: [PANE2_TASK]
- Pane 3: [PANE3_TASK]
- Pane 4: [PANE4_TASK]

### Additional Context
<!-- OPTIONAL: Any additional information that might be helpful -->
[ADDITIONAL_CONTEXT]

---

## OPERATOR EXECUTION CHECKLIST

When executing the above task:

1. [ ] Read and understand the user's task specification
2. [ ] Set up the tmux environment (Phase 1)
3. [ ] Choose appropriate task pattern from Phase 2 based on task type
4. [ ] Replace placeholders with actual task details
5. [ ] Execute task assignment commands
6. [ ] Monitor progress using Phase 3 tools
7. [ ] Collect results using Phase 4 tools
8. [ ] Generate final report with actual results
9. [ ] Clean up resources using Phase 5 tools
