# Node.js PTY Solutions for Claude CLI Background Execution

## Problem Statement

The Claude CLI fails when executed in background processes with the error:
```
Error: Raw mode is not supported on the current process.stdin, which Ink uses as input stream by default.
```

This occurs because Claude CLI uses the Ink library for interactive terminal UI, which requires raw mode TTY access that's not available in background processes.

## Root Cause Analysis

1. **Ink Dependency**: Claude CLI uses Ink (React for CLI) which requires `process.stdin.setRawMode()`
2. **TTY Detection**: When Node.js detects no TTY attached, `process.stdin.setRawMode` becomes undefined
3. **Background Process Limitation**: Standard `child_process.spawn()` doesn't provide pseudo-terminal environment

## Solution 1: node-pty Library (Recommended)

### Installation
```bash
npm install node-pty
# or
yarn add node-pty
```

### Basic Claude CLI Spawning
```javascript
const pty = require('node-pty');
const os = require('os');

function spawnClaudeWithPTY(command, args = []) {
    const ptyProcess = pty.spawn('claude', args, {
        name: 'xterm-color',
        cols: 120,
        rows: 30,
        cwd: process.cwd(),
        env: {
            ...process.env,
            TERM: 'xterm-256color'
        }
    });

    return ptyProcess;
}

// Example usage
const claudeProcess = spawnClaudeWithPTY('claude', [
    '--dangerously-skip-permissions',
    'Please analyze the current directory structure'
]);

claudeProcess.onData((data) => {
    console.log('Claude output:', data);
});

claudeProcess.onExit((exitCode) => {
    console.log('Claude exited with code:', exitCode);
});
```

### Advanced Multi-Worker Implementation
```javascript
const pty = require('node-pty');
const fs = require('fs').promises;
const path = require('path');

class ClaudeWorkerManager {
    constructor(workerCount = 4) {
        this.workers = [];
        this.workerCount = workerCount;
        this.workDir = process.cwd();
    }

    async createWorker(workerId, instructions) {
        return new Promise((resolve, reject) => {
            // Create worker instruction file
            const instructionFile = path.join(this.workDir, `worker${workerId}_instructions.md`);
            fs.writeFile(instructionFile, instructions);

            // Spawn Claude with PTY
            const worker = pty.spawn('claude', [
                '--dangerously-skip-permissions',
                `Please read ${instructionFile} and execute the task. Write status updates to comm/worker${workerId}_status.txt`
            ], {
                name: 'xterm-color',
                cols: 120,
                rows: 30,
                cwd: this.workDir,
                env: {
                    ...process.env,
                    WORKER_ID: workerId.toString(),
                    TERM: 'xterm-256color'
                }
            });

            // Setup logging
            const logFile = path.join(this.workDir, 'logs', `worker${workerId}.log`);
            const logStream = fs.createWriteStream(logFile, { flags: 'a' });

            worker.onData((data) => {
                logStream.write(data);
                console.log(`[Worker${workerId}] ${data.trim()}`);
            });

            worker.onExit((exitCode) => {
                logStream.end();
                console.log(`Worker ${workerId} exited with code: ${exitCode}`);
            });

            this.workers.push({
                id: workerId,
                process: worker,
                instructionFile,
                logFile
            });

            resolve(worker);
        });
    }

    async spawnAllWorkers(taskBreakdown) {
        const workerPromises = [];
        
        for (let i = 1; i <= this.workerCount; i++) {
            const instructions = this.generateWorkerInstructions(i, taskBreakdown[i - 1]);
            workerPromises.push(this.createWorker(i, instructions));
        }

        return Promise.all(workerPromises);
    }

    generateWorkerInstructions(workerId, task) {
        return `# Worker ${workerId} Instructions

## Task Assignment
${task.description}

## Specific Requirements
${task.requirements.join('\n- ')}

## Communication Protocol
- Write status updates to: comm/worker${workerId}_status.txt
- Format: echo "[Worker${workerId}] Status: Your message" >> comm/worker${workerId}_status.txt
- Report progress every 5-10 minutes
- Mark completion with: echo "[Worker${workerId}] COMPLETED: Summary" >> comm/worker${workerId}_status.txt

## Output Location
Save all work to: outputs/${task.outputDir}/

## Completion Criteria
${task.completionCriteria}
`;
    }

    async terminateAllWorkers() {
        for (const worker of this.workers) {
            worker.process.kill('SIGTERM');
            // Clean up instruction files
            try {
                await fs.unlink(worker.instructionFile);
            } catch (err) {
                console.warn(`Could not delete ${worker.instructionFile}: ${err.message}`);
            }
        }
        this.workers = [];
    }
}

// Usage example
async function runParallelClaude() {
    const manager = new ClaudeWorkerManager(4);
    
    const taskBreakdown = [
        {
            description: "Develop backend API endpoints",
            requirements: ["REST API design", "Authentication", "Database integration"],
            outputDir: "backend",
            completionCriteria: "All endpoints documented and tested"
        },
        {
            description: "Create frontend components", 
            requirements: ["React components", "State management", "UI/UX design"],
            outputDir: "frontend",
            completionCriteria: "Components functional and styled"
        },
        {
            description: "Write comprehensive tests",
            requirements: ["Unit tests", "Integration tests", "E2E tests"],
            outputDir: "tests",
            completionCriteria: "95% test coverage achieved"
        },
        {
            description: "Create documentation and deployment guides",
            requirements: ["API documentation", "Setup instructions", "Deployment guide"],
            outputDir: "docs",
            completionCriteria: "Documentation complete and verified"
        }
    ];

    try {
        await manager.spawnAllWorkers(taskBreakdown);
        
        // Monitor workers (simplified)
        setInterval(() => {
            console.log(`Active workers: ${manager.workers.length}`);
        }, 30000);
        
        // Cleanup after some time or on completion
        process.on('SIGINT', async () => {
            console.log('Terminating all workers...');
            await manager.terminateAllWorkers();
            process.exit(0);
        });
        
    } catch (error) {
        console.error('Error managing workers:', error);
        await manager.terminateAllWorkers();
    }
}
```

## Solution 2: child_pty Alternative

### Installation
```bash
npm install child_pty
```

### Implementation
```javascript
const childPty = require('child_pty');

function spawnClaudeWithChildPty(args = []) {
    const child = childPty.spawn('claude', [
        '--dangerously-skip-permissions',
        ...args
    ], {
        cwd: process.cwd(),
        env: process.env
    });

    child.stdout.on('data', (data) => {
        console.log('stdout:', data.toString());
    });

    child.stderr.on('data', (data) => {
        console.error('stderr:', data.toString());
    });

    child.on('exit', (code) => {
        console.log(`Child exited with code ${code}`);
    });

    return child;
}
```

## Solution 3: Custom PTY Wrapper

For more control, you can create a custom wrapper:

```javascript
const { spawn } = require('child_process');
const pty = require('node-pty');

class ClaudePTYWrapper {
    constructor(options = {}) {
        this.options = {
            cols: 120,
            rows: 30,
            shell: false,
            ...options
        };
        this.process = null;
        this.outputBuffer = '';
        this.callbacks = {
            data: [],
            exit: [],
            error: []
        };
    }

    spawn(args = []) {
        this.process = pty.spawn('claude', args, {
            name: 'xterm-color',
            cols: this.options.cols,
            rows: this.options.rows,
            cwd: process.cwd(),
            env: {
                ...process.env,
                TERM: 'xterm-256color',
                // Prevent some Ink issues
                CI: 'true'
            }
        });

        this.process.onData((data) => {
            this.outputBuffer += data;
            this.callbacks.data.forEach(cb => cb(data));
        });

        this.process.onExit((exitCode) => {
            this.callbacks.exit.forEach(cb => cb(exitCode));
        });

        return this;
    }

    write(input) {
        if (this.process) {
            this.process.write(input);
        }
        return this;
    }

    onData(callback) {
        this.callbacks.data.push(callback);
        return this;
    }

    onExit(callback) {
        this.callbacks.exit.push(callback);
        return this;
    }

    onError(callback) {
        this.callbacks.error.push(callback);
        return this;
    }

    kill(signal = 'SIGTERM') {
        if (this.process) {
            this.process.kill(signal);
        }
    }

    resize(cols, rows) {
        if (this.process) {
            this.process.resize(cols, rows);
        }
    }

    getOutput() {
        return this.outputBuffer;
    }
}

// Usage
const claudeWrapper = new ClaudePTYWrapper({
    cols: 100,
    rows: 50
});

claudeWrapper
    .spawn(['--dangerously-skip-permissions', 'Analyze the current project'])
    .onData((data) => {
        console.log('Received:', data);
    })
    .onExit((code) => {
        console.log('Process finished with code:', code);
    });
```

## Solution 4: Environment Variable Workarounds

Some Ink issues can be mitigated with environment variables:

```javascript
const pty = require('node-pty');

function spawnClaudeWithEnvWorkarounds(args = []) {
    const env = {
        ...process.env,
        // Ink workarounds
        CI: 'true',
        TERM: 'xterm-256color',
        // Disable some terminal features that might cause issues
        NO_COLOR: '1',
        // Force non-interactive mode for some tools
        DEBIAN_FRONTEND: 'noninteractive'
    };

    return pty.spawn('claude', args, {
        name: 'xterm-color',
        cols: 120,
        rows: 30,
        cwd: process.cwd(),
        env: env
    });
}
```

## Solution 5: Docker-based Isolation

For production environments, consider running Claude CLI in containers:

```javascript
const pty = require('node-pty');

function spawnClaudeInDocker(args = [], containerOptions = {}) {
    const dockerArgs = [
        'run',
        '--rm',
        '-i',
        '--tty',
        '-v', `${process.cwd()}:/workspace`,
        '-w', '/workspace',
        containerOptions.image || 'node:18-alpine',
        'claude',
        ...args
    ];

    return pty.spawn('docker', dockerArgs, {
        name: 'xterm-color',
        cols: 120,
        rows: 30,
        cwd: process.cwd(),
        env: process.env
    });
}
```

## Complete Working Example

Here's a complete example that implements parallel Claude CLI execution:

```javascript
const pty = require('node-pty');
const fs = require('fs').promises;
const path = require('path');

class ParallelClaudeRunner {
    constructor(config = {}) {
        this.workDir = config.workDir || process.cwd();
        this.maxWorkers = config.maxWorkers || 4;
        this.workers = new Map();
        this.results = new Map();
    }

    async setupDirectories() {
        const dirs = ['logs', 'comm', 'outputs', 'outputs/reports'];
        for (const dir of dirs) {
            await fs.mkdir(path.join(this.workDir, dir), { recursive: true });
        }
    }

    async createWorkerInstructions(workerId, task) {
        const instructions = `# Worker ${workerId} Task Instructions

## Objective
${task.objective}

## Specific Tasks
${task.tasks.map(t => `- ${t}`).join('\n')}

## Output Requirements
- Save all work to: outputs/${task.category}/
- Log progress to: comm/worker${workerId}_status.txt
- Final deliverable: ${task.deliverable}

## Communication Format
Use this format for status updates:
\`\`\`bash
echo "[$(date)] Worker${workerId}: Status message" >> comm/worker${workerId}_status.txt
\`\`\`

Mark completion with:
\`\`\`bash
echo "[$(date)] Worker${workerId}: COMPLETED - ${task.deliverable}" >> comm/worker${workerId}_status.txt
\`\`\`
`;

        const filePath = path.join(this.workDir, `worker${workerId}_instructions.md`);
        await fs.writeFile(filePath, instructions);
        return filePath;
    }

    async spawnWorker(workerId, task) {
        const instructionFile = await this.createWorkerInstructions(workerId, task);
        
        const worker = pty.spawn('claude', [
            '--dangerously-skip-permissions',
            `follow ${path.basename(instructionFile)}`
        ], {
            name: 'xterm-color',
            cols: 120,
            rows: 30,
            cwd: this.workDir,
            env: {
                ...process.env,
                WORKER_ID: workerId.toString(),
                TERM: 'xterm-256color'
            }
        });

        // Setup logging
        const logPath = path.join(this.workDir, 'logs', `worker${workerId}.log`);
        let output = '';

        worker.onData((data) => {
            output += data;
            fs.appendFile(logPath, data).catch(console.error);
        });

        worker.onExit((exitCode) => {
            console.log(`Worker ${workerId} completed with exit code: ${exitCode}`);
            this.results.set(workerId, { exitCode, output, task });
            this.workers.delete(workerId);
        });

        this.workers.set(workerId, { process: worker, task, instructionFile });
        return worker;
    }

    async runParallelTasks(tasks) {
        await this.setupDirectories();
        
        const workerPromises = tasks.map((task, index) => {
            const workerId = index + 1;
            return this.spawnWorker(workerId, task);
        });

        return Promise.all(workerPromises);
    }

    async monitorProgress() {
        const interval = setInterval(async () => {
            console.log(`\n=== Progress Report (${new Date().toISOString()}) ===`);
            console.log(`Active workers: ${this.workers.size}`);
            
            for (const [workerId] of this.workers) {
                const statusFile = path.join(this.workDir, 'comm', `worker${workerId}_status.txt`);
                try {
                    const status = await fs.readFile(statusFile, 'utf8');
                    const lastLine = status.trim().split('\n').pop();
                    console.log(`Worker ${workerId}: ${lastLine}`);
                } catch (err) {
                    console.log(`Worker ${workerId}: No status yet`);
                }
            }

            if (this.workers.size === 0) {
                clearInterval(interval);
                await this.generateFinalReport();
            }
        }, 30000); // Check every 30 seconds
    }

    async generateFinalReport() {
        const report = `# Parallel Claude Execution Report

## Execution Summary
- Total workers: ${this.results.size}
- Completion time: ${new Date().toISOString()}
- Work directory: ${this.workDir}

## Worker Results
${Array.from(this.results.entries()).map(([workerId, result]) => `
### Worker ${workerId}
- Task: ${result.task.objective}
- Exit Code: ${result.exitCode}
- Output Length: ${result.output.length} characters
`).join('\n')}

## Generated Files
${await this.listOutputFiles()}
`;

        const reportPath = path.join(this.workDir, 'outputs', 'reports', 'execution_report.md');
        await fs.writeFile(reportPath, report);
        console.log(`\nFinal report generated: ${reportPath}`);
    }

    async listOutputFiles() {
        try {
            const outputDir = path.join(this.workDir, 'outputs');
            const files = await this.getAllFiles(outputDir);
            return files.map(f => `- ${path.relative(this.workDir, f)}`).join('\n');
        } catch (err) {
            return '- No output files found';
        }
    }

    async getAllFiles(dir) {
        const files = [];
        const items = await fs.readdir(dir, { withFileTypes: true });
        
        for (const item of items) {
            const fullPath = path.join(dir, item.name);
            if (item.isDirectory()) {
                files.push(...await this.getAllFiles(fullPath));
            } else {
                files.push(fullPath);
            }
        }
        
        return files;
    }

    async cleanup() {
        // Terminate any remaining workers
        for (const [workerId, worker] of this.workers) {
            worker.process.kill('SIGTERM');
            
            // Clean up instruction file
            try {
                await fs.unlink(worker.instructionFile);
            } catch (err) {
                console.warn(`Could not clean up ${worker.instructionFile}`);
            }
        }
        
        this.workers.clear();
    }
}

// Usage Example
async function main() {
    const runner = new ParallelClaudeRunner({
        workDir: process.cwd(),
        maxWorkers: 4
    });

    const tasks = [
        {
            objective: "Analyze project structure and create architecture documentation",
            category: "analysis",
            tasks: [
                "Examine all source files",
                "Document dependencies and relationships", 
                "Create architecture diagrams"
            ],
            deliverable: "architecture_analysis.md"
        },
        {
            objective: "Review code quality and suggest improvements",
            category: "review",
            tasks: [
                "Analyze code patterns",
                "Identify potential issues",
                "Suggest optimizations"
            ],
            deliverable: "code_review.md"
        },
        {
            objective: "Generate comprehensive test suite",
            category: "testing", 
            tasks: [
                "Create unit tests",
                "Design integration tests",
                "Write test documentation"
            ],
            deliverable: "test_suite/"
        },
        {
            objective: "Create deployment and maintenance documentation",
            category: "docs",
            tasks: [
                "Write deployment guide",
                "Create maintenance procedures",
                "Document troubleshooting steps"
            ],
            deliverable: "deployment_guide.md"
        }
    ];

    try {
        console.log('Starting parallel Claude execution...');
        await runner.runParallelTasks(tasks);
        
        // Start monitoring
        runner.monitorProgress();
        
        // Cleanup on exit
        process.on('SIGINT', async () => {
            console.log('\nShutting down...');
            await runner.cleanup();
            process.exit(0);
        });
        
    } catch (error) {
        console.error('Error running parallel tasks:', error);
        await runner.cleanup();
        process.exit(1);
    }
}

// Run the example
if (require.main === module) {
    main();
}

module.exports = { ParallelClaudeRunner };
```

## Key Implementation Notes

1. **Error Handling**: Always implement proper error handling and cleanup for PTY processes
2. **Resource Management**: Limit the number of concurrent Claude instances based on system resources
3. **Security**: Consider running in containers for production environments
4. **Monitoring**: Implement proper logging and monitoring for background processes
5. **Graceful Shutdown**: Handle process termination properly to avoid orphaned processes

## Performance Considerations

- **Memory Usage**: Each Claude instance may use 1-2GB of memory
- **CPU Usage**: PTY processes have minimal CPU overhead
- **Concurrency**: Start with 2-4 workers and scale based on system performance
- **File I/O**: Use async file operations to prevent blocking

## Troubleshooting

1. **Installation Issues**: Ensure node-pty native dependencies are properly compiled
2. **Permission Errors**: Run with appropriate permissions or use `--dangerously-skip-permissions`
3. **Resource Limits**: Monitor system resources and adjust worker count accordingly
4. **Process Cleanup**: Implement proper signal handling to prevent orphaned processes

This comprehensive solution provides multiple approaches to solve the Claude CLI TTY limitation, with the node-pty library being the most robust and recommended approach for production use.