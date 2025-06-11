# Multi-Instance Claude Code Task Management System

## Overview

This system enables efficient parallel task execution using multiple Claude Code instances managed through tmux. It supports various task types including development, research, content creation, problem-solving, and collaborative discussions, with built-in coordination and monitoring capabilities.

## Key Features

- **Multi-Agent Coordination**: Run up to 5 Claude Code instances in parallel
- **Versatile Task Support**: Handle development, research, content creation, problem-solving, and discussions
- **Automated Task Distribution**: Smart workload allocation across instances
- **Real-time Progress Tracking**: Built-in reporting and monitoring system
- **Resource Management**: Token usage monitoring and optimization
- **Pipeline Processing**: Support for dependent and sequential tasks

## Prerequisites

- tmux (Terminal Multiplexer)
- Claude Code CLI installed and configured
- Unix-like environment (Linux/macOS/WSL)

## Quick Start

### 1. Edit your task
Open `instruction.md` and fill in the **USER TASK SPECIFICATION** section at the bottom with your specific task details.

### 2. Start tmux session
```bash
tmux
```

### 3. Launch Claude Code
```bash
claude --dangerously-skip-permissions
```
>[!WARNING]
>`--dangerously-skip-permissions` Use at your own risk!

### 4. Execute your task
Simply tell Claude:
```
follow instruction.md
```

Claude will automatically:
- Read your task specification
- Set up the multi-instance environment
- Distribute work across panes
- Execute the task
- Generate results and reports

## Project Structure

```
/
├── README.md          # This file
└── instruction.md     # Detailed task execution manual with templates
```

## Supported Task Types

### 1. Development Tasks
- **Backend API Development**: RESTful APIs, GraphQL, microservices
- **Frontend Implementation**: React, Vue, Angular components
- **Database Design**: Schema design, optimization, migrations
- **Testing**: Unit tests, integration tests, E2E tests

### 2. Research & Analysis Tasks
- **Literature Review**: Academic papers, technical documentation
- **Data Collection**: Web scraping, API integration, surveys
- **Statistical Analysis**: Data processing, visualization, insights
- **Report Generation**: Findings compilation, recommendations

### 3. Content Creation Tasks
- **Research & Fact-checking**: Source verification, accuracy checks
- **Content Drafting**: Articles, documentation, tutorials
- **Supporting Materials**: Code examples, diagrams, images
- **Editing & Formatting**: Proofreading, style consistency

### 4. Problem-Solving Tasks
- **Algorithm Development**: Multiple approach implementations
- **Performance Testing**: Benchmarking, optimization
- **Solution Comparison**: Trade-off analysis, recommendations
- **Integration**: Combining best approaches

### 5. Collaborative Discussions
- **Multi-perspective Analysis**: Different viewpoints on topics
- **Brainstorming**: Idea generation and evaluation
- **Decision Making**: Pros/cons analysis, consensus building
- **Knowledge Synthesis**: Combining insights from all agents

## Usage Examples

### Development Task Example
```bash
# Replace placeholders with your specific requirements
tmux send-keys -t $PANE1 "You are pane1. Create a REST API for user management. Use Express.js. Save to api/users.js. Report: tmux send-keys -t $MAIN_PANE '[pane1] API created' Enter" Enter
```

### Research Task Example
```bash
# Parallel research across multiple sources
tmux send-keys -t $PANE1 "You are pane1. Research machine learning trends for 2024. Find 10 sources. Save to ml_trends.md. Report findings." Enter
```

### Pipeline Processing Example
```bash
# Sequential task execution with dependencies
# Pane1: Data collection → Pane2: Processing → Pane3: Analysis → Pane4: Visualization
# See instruction.md Phase 3 for coordination patterns
```

## Best Practices

1. **Resource Management**
   - Monitor token usage with `ccusage` command
   - Clear context when exceeding 50k tokens
   - Use batch operations for efficiency

2. **Error Handling**
   - Implement timeout mechanisms for long-running tasks
   - Use health checks before critical operations
   - Maintain fallback strategies

3. **Task Organization**
   - Use clear naming conventions with pane IDs
   - Implement structured reporting formats
   - Track task dependencies explicitly

## Troubleshooting

### Emergency Stop
```bash
tmux kill-server
```
**WARNING**: This will terminate ALL tmux sessions and their processes immediately. Use this when you need to stop everything quickly.

### Common Issues

1. **Pane Not Responding**
   - Send Ctrl+C: `tmux send-keys -t $PANE C-c`
   - Clear and restart: `/clear` command

2. **Memory Issues**
   - Clear all panes simultaneously
   - Check system resources with `htop`

3. **Synchronization Problems**
   - Implement barrier synchronization (see instruction.md section 10.3)
   - Use completion markers in output

## Security Considerations

- The `--dangerously-skip-permissions` flag should only be used in development environments
- Avoid processing sensitive information across multiple panes
- Regularly clean up log files and temporary data

## Advanced Features

### Token Management
```bash
# Check token usage across all panes
for pane in $PANE1 $PANE2 $PANE3 $PANE4; do
    tmux send-keys -t $pane "ccusage" Enter
done
```

### Health Monitoring
```bash
# Monitor pane status and detect errors
health_check()  # Function available in instruction.md
```

### Results Collection
```bash
# Automatically collect outputs from all panes
collect_results()  # Creates results/ directory with all outputs
```

## Contributing

When contributing to this project:
1. Test multi-instance coordination thoroughly
2. Document any new task patterns or utilities
3. Ensure backward compatibility with existing workflows
4. Add examples for new task types

## References

- [Task Execution Manual](./instruction.md)
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)

---

## Appendix: Task Specification Examples

### Example 1: Web Application Development

```markdown
### Task Type
development

### Task Description
Create a full-stack todo application with user authentication, real-time updates, and a modern UI

### Specific Requirements
1. Backend: Node.js with Express, JWT authentication, PostgreSQL database
2. Frontend: React with TypeScript, Material-UI components, responsive design
3. Real-time updates using WebSocket (Socket.io)
4. Docker configuration for easy deployment
5. Comprehensive test coverage (unit and integration tests)

### Expected Outputs
1. Backend API code in `backend/` directory
2. Frontend application in `frontend/` directory
3. Database schema and migration files
4. Docker Compose configuration
5. README with setup instructions

### Task Distribution Plan
- Pane 1: Backend API development and database design
- Pane 2: Frontend UI implementation and state management
- Pane 3: Authentication system and WebSocket integration
- Pane 4: Testing, Docker configuration, and documentation

### Additional Context
Priority is on clean, maintainable code with proper error handling. Follow REST API best practices and React hooks patterns.
```

### Example 2: Market Research Report

```markdown
### Task Type
research

### Task Description
Analyze the current state of AI-powered code generation tools market, focusing on competitive landscape, pricing models, and future trends

### Specific Requirements
1. Research at least 10 major players in the market
2. Compare features, pricing, and target audiences
3. Analyze market trends for the next 2-3 years
4. Include data visualizations (charts/graphs)
5. Provide actionable recommendations for a startup entering this space

### Expected Outputs
1. Comprehensive market analysis report (15-20 pages)
2. Executive summary (2 pages)
3. Competitor comparison matrix
4. Market trend visualizations
5. SWOT analysis for new market entrants

### Task Distribution Plan
- Pane 1: Research major players and collect feature/pricing data
- Pane 2: Analyze market trends and future predictions
- Pane 3: Create visualizations and comparison matrices
- Pane 4: Write report sections and executive summary

### Additional Context
Focus on tools similar to GitHub Copilot, Cursor, and Tabnine. Include both established companies and promising startups.
```

### Example 3: Technical Blog Series

```markdown
### Task Type
content

### Task Description
Create a 5-part blog series explaining microservices architecture patterns for beginners, with practical examples

### Specific Requirements
1. Each article should be 1500-2000 words
2. Include code examples in Node.js and Python
3. Create diagrams for each architectural pattern
4. Write in an engaging, beginner-friendly tone
5. Include real-world use cases and best practices

### Expected Outputs
1. Five blog posts in Markdown format
2. Code examples repository with working demos
3. Architecture diagrams (using mermaid or similar)
4. Series outline and publishing schedule
5. Social media snippets for promotion

### Task Distribution Plan
- Pane 1: Research and outline creation for all articles
- Pane 2: Write main content for articles 1-3
- Pane 3: Write main content for articles 4-5 and create code examples
- Pane 4: Create diagrams, review/edit all content, prepare social media snippets

### Additional Context
Target audience: Junior developers with 1-2 years experience. Avoid overly technical jargon. Each article should build upon the previous one.
```

### Example 4: Algorithm Optimization Challenge

```markdown
### Task Type
problem-solving

### Task Description
Optimize a large-scale graph traversal algorithm for social network analysis that currently takes too long on datasets with millions of nodes

### Specific Requirements
1. Current algorithm has O(n²) complexity - need to reduce to O(n log n) or better
2. Must handle graphs with 10M+ nodes and 100M+ edges
3. Implement in both Python and C++ for comparison
4. Memory usage should not exceed 16GB
5. Maintain accuracy of original algorithm (tolerance: 0.001%)

### Expected Outputs
1. Optimized algorithm implementations (Python and C++)
2. Performance benchmark results and comparisons
3. Memory usage analysis
4. Scalability test results
5. Technical documentation explaining optimizations

### Task Distribution Plan
- Pane 1: Analyze current algorithm and design optimization approach A
- Pane 2: Design alternative optimization approach B
- Pane 3: Implement both approaches and create benchmarks
- Pane 4: Test scalability, accuracy, and create documentation

### Additional Context
The algorithm is used for community detection in social networks. Current implementation uses adjacency matrix representation. Consider using sparse matrix techniques or graph streaming algorithms.
```

### Example 5: Technology Stack Evaluation

```markdown
### Task Type
discussion

### Task Description
Evaluate and recommend the best technology stack for a new fintech startup's mobile-first banking application

### Specific Requirements
1. Consider security, scalability, and regulatory compliance
2. Evaluate both native and cross-platform mobile options
3. Include cost analysis for different stack options
4. Consider developer availability and ecosystem maturity
5. Provide migration path from MVP to enterprise scale

### Expected Outputs
1. Technology stack comparison report
2. Detailed pros/cons for each option
3. Cost projection for 3-year timeline
4. Risk assessment matrix
5. Final recommendation with justification

### Task Distribution Plan
- Pane 1: Evaluate backend technologies (focus on security and compliance)
- Pane 2: Analyze mobile development options (native vs cross-platform)
- Pane 3: Research infrastructure and DevOps considerations
- Pane 4: Cost analysis and risk assessment

### Additional Context
The startup expects 100K users in year 1, scaling to 5M by year 3. Must comply with PCI-DSS and regional banking regulations. Team currently has 5 developers with varied backgrounds.
```

### Simple Task Examples

You don't always need to fill out every field. Here are some minimal examples that work just as well:

#### Ultra-Simple Examples (Description Only)

```markdown
### Task Description
Analyze this codebase from 4 perspectives: security vulnerabilities, performance bottlenecks, code quality issues, and architectural improvements. Create a unified improvement plan.
```

```markdown
### Task Description
Build a real-time chat application with separate teams handling: WebSocket server, React frontend, user authentication, and MongoDB database integration. Make them work together.
```

```markdown
### Task Description
Research "AI in healthcare" from multiple angles: current applications, ethical concerns, regulatory challenges, and future possibilities. Synthesize findings into a comprehensive report.
```

```markdown
### Task Description
Create a Python package for data visualization with 4 parallel workstreams: core plotting engine, statistical analysis tools, interactive widgets, and comprehensive documentation with examples.
```

```markdown
### Task Description
Debate the pros and cons of microservices vs monolithic architecture from different expert perspectives, then reach a consensus recommendation for a growing startup.
```

#### Simple Examples with Task Type

```markdown
### Task Type
discussion

### Task Description
Have 4 AI experts from different backgrounds (philosophy, neuroscience, computer science, ethics) discuss consciousness in artificial intelligence and find common ground
```

```markdown
### Task Type
development

### Task Description
Refactor this legacy codebase by having 4 teams work simultaneously: one modernizing the frontend, one updating the backend API, one improving the database schema, and one writing tests
```

```markdown
### Task Type
research

### Task Description
Investigate "sustainable technology" with parallel research on: renewable energy innovations, circular economy models, green computing practices, and environmental impact metrics
```

```markdown
### Task Type
content

### Task Description
Create a comprehensive course on machine learning: one team writes theory lessons, another creates coding exercises, a third develops real-world projects, and a fourth produces video script outlines
```

```markdown
### Task Type
problem-solving

### Task Description
Optimize this e-commerce platform's performance using 4 approaches: database query optimization, caching strategies, frontend bundle size reduction, and API response time improvements
```

### Tips for Writing Task Specifications

1. **Start Simple**: You can begin with just the task type and description
2. **Add Detail as Needed**: Include requirements and outputs only when necessary
3. **Let Claude Decide**: If you don't specify task distribution, Claude will handle it automatically
4. **Be Specific When It Matters**: Add details for complex tasks or specific requirements
5. **Use Natural Language**: Write tasks as you would explain them to a colleague
