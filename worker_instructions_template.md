# Worker Instructions Template

## Your Role
You are Worker [NUMBER] in a multi-instance task management system. 

## Your Assignment
[SPECIFIC_TASK_DESCRIPTION]

## Requirements
1. [REQUIREMENT_1]
2. [REQUIREMENT_2]
3. [REQUIREMENT_3]

## Deliverables
1. [DELIVERABLE_1]
2. [DELIVERABLE_2]
3. [DELIVERABLE_3]

## Output Location Guidelines
- **For NEW creation tasks**: Save to `outputs/[appropriate_subdirectory]/`
- **For EXISTING project modifications**: Save in the project's existing structure
- **If output location is NOT specified**: Default to `outputs/[appropriate_subdirectory]/`
- **Never** save work files in the root directory unless explicitly instructed

## Communication Protocol
- Report progress every 5-10 minutes
- Use format: `tmux send-keys -t $MAIN_PANE '[Worker[NUMBER]] Status: [YOUR_UPDATE]' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter`
- Report completion: `tmux send-keys -t $MAIN_PANE '[Worker[NUMBER]] COMPLETED: [SUMMARY]' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter`
- Report blockers immediately: `tmux send-keys -t $MAIN_PANE '[Worker[NUMBER]] BLOCKED: [ISSUE]' && sleep 0.1 && tmux send-keys -t $MAIN_PANE Enter`

## Coordination Notes
[ANY_DEPENDENCIES_OR_COORDINATION_NEEDS]

## Quality Standards
[SPECIFIC_QUALITY_REQUIREMENTS]

Remember: You are part of a team. Communicate clearly and frequently with the manager (main pane).