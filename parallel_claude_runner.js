#!/usr/bin/env node

/**
 * Parallel Claude CLI Runner using node-pty
 * Solves TTY limitation by providing proper pseudo-terminal environment
 */

const pty = require('node-pty');
const fs = require('fs');
const path = require('path');
const os = require('os');

class ParallelClaudeRunner {
    constructor(workDir = process.cwd(), maxWorkers = 4) {
        this.workDir = workDir;
        this.maxWorkers = maxWorkers;
        this.workers = new Map();
        this.logDir = path.join(workDir, 'logs');
        this.commDir = path.join(workDir, 'comm');
        
        // Ensure directories exist
        this.ensureDirectories();
    }

    ensureDirectories() {
        [this.logDir, this.commDir].forEach(dir => {
            if (!fs.existsSync(dir)) {
                fs.mkdirSync(dir, { recursive: true });
            }
        });
    }

    async startWorker(workerId, instructionFile) {
        const workerLogPath = path.join(this.logDir, `worker${workerId}.log`);
        const workerStatusPath = path.join(this.commDir, `worker${workerId}_status.txt`);
        const workerPidPath = path.join(this.commDir, `worker${workerId}.pid`);

        // Claude command with instruction to read file and communicate via status file
        const claudeCommand = [
            'claude',
            '--dangerously-skip-permissions',
            `"Please read ${instructionFile} and execute the task. Write status updates to ${workerStatusPath} using the format: echo '[Worker${workerId}] Status: Your message' >> ${workerStatusPath}. Mark completion with COMPLETED: when done."`
        ].join(' ');

        console.log(`Starting Worker ${workerId}...`);
        console.log(`Command: ${claudeCommand}`);

        // Create PTY process - this provides the TTY environment Claude CLI needs
        const ptyProcess = pty.spawn('bash', ['-c', claudeCommand], {
            name: 'xterm-color',
            cols: 80,
            rows: 30,
            cwd: this.workDir,
            env: {
                ...process.env,
                TERM: 'xterm-256color',
                // These environment variables help with Ink compatibility
                CI: 'false',
                FORCE_COLOR: '1',
                NODE_NO_READLINE: '1'
            }
        });

        // Store worker info
        this.workers.set(workerId, {
            process: ptyProcess,
            logPath: workerLogPath,
            statusPath: workerStatusPath,
            pidPath: workerPidPath,
            startTime: new Date()
        });

        // Save PID for external monitoring
        fs.writeFileSync(workerPidPath, ptyProcess.pid.toString());

        // Create log file stream
        const logStream = fs.createWriteStream(workerLogPath);

        // Handle PTY data (all output from Claude CLI)
        ptyProcess.onData((data) => {
            logStream.write(data);
            // Optionally log to console for debugging
            // process.stdout.write(`[Worker${workerId}] ${data}`);
        });

        // Handle process exit
        ptyProcess.onExit((exitCode, signal) => {
            console.log(`Worker ${workerId} exited with code ${exitCode}, signal ${signal}`);
            logStream.end();
            
            // Write final status if not already completed
            if (fs.existsSync(workerStatusPath)) {
                const status = fs.readFileSync(workerStatusPath, 'utf8');
                if (!status.includes('COMPLETED:')) {
                    this.writeWorkerStatus(workerId, `TERMINATED: Process exited with code ${exitCode}`);
                }
            }
            
            // Cleanup PID file
            if (fs.existsSync(workerPidPath)) {
                fs.unlinkSync(workerPidPath);
            }
            
            this.workers.delete(workerId);
        });

        // Initial status
        this.writeWorkerStatus(workerId, 'Initializing worker process');

        return workerId;
    }

    writeWorkerStatus(workerId, message) {
        const statusPath = path.join(this.commDir, `worker${workerId}_status.txt`);
        const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
        const statusLine = `[${timestamp}] [Worker${workerId}] ${message}\n`;
        fs.appendFileSync(statusPath, statusLine);
    }

    async startAllWorkers(instructionFiles) {
        const workerPromises = [];
        
        for (let i = 0; i < Math.min(instructionFiles.length, this.maxWorkers); i++) {
            const workerId = i + 1;
            const instructionFile = instructionFiles[i];
            
            if (fs.existsSync(instructionFile)) {
                workerPromises.push(this.startWorker(workerId, instructionFile));
                // Stagger worker starts to avoid overwhelming the system
                await new Promise(resolve => setTimeout(resolve, 2000));
            } else {
                console.warn(`Instruction file not found: ${instructionFile}`);
            }
        }

        return Promise.all(workerPromises);
    }

    getWorkerStatus() {
        const status = {
            active: this.workers.size,
            workers: {}
        };

        for (const [workerId, worker] of this.workers) {
            const isRunning = worker.process.pid && !worker.process.killed;
            const statusFile = worker.statusPath;
            let lastStatus = 'No status yet';
            
            if (fs.existsSync(statusFile)) {
                const content = fs.readFileSync(statusFile, 'utf8').trim();
                const lines = content.split('\n');
                lastStatus = lines[lines.length - 1] || 'No status yet';
            }

            status.workers[workerId] = {
                running: isRunning,
                pid: worker.process.pid,
                startTime: worker.startTime,
                lastStatus: lastStatus
            };
        }

        return status;
    }

    checkCompletion() {
        let completed = 0;
        let total = 0;

        for (let i = 1; i <= this.maxWorkers; i++) {
            const statusFile = path.join(this.commDir, `worker${i}_status.txt`);
            if (fs.existsSync(statusFile)) {
                total++;
                const content = fs.readFileSync(statusFile, 'utf8');
                if (content.includes('COMPLETED:')) {
                    completed++;
                }
            }
        }

        return { completed, total, allCompleted: completed === total && total > 0 };
    }

    async monitorWorkers(intervalMs = 10000) {
        console.log('Starting worker monitoring...');
        
        const monitor = setInterval(() => {
            console.clear();
            console.log('=== PARALLEL CLAUDE WORKER MONITOR ===');
            console.log(`Time: ${new Date().toLocaleString()}`);
            console.log('');

            const status = this.getWorkerStatus();
            console.log(`Active Workers: ${status.active}`);
            console.log('');

            for (const [workerId, workerStatus] of Object.entries(status.workers)) {
                const runningIcon = workerStatus.running ? '🟢' : '🔴';
                const runtime = Math.floor((Date.now() - new Date(workerStatus.startTime)) / 1000);
                console.log(`${runningIcon} Worker ${workerId} (PID: ${workerStatus.pid}, Runtime: ${runtime}s)`);
                console.log(`   Status: ${workerStatus.lastStatus}`);
                console.log('');
            }

            // Check for completion
            const completion = this.checkCompletion();
            console.log(`Progress: ${completion.completed}/${completion.total} workers completed`);

            if (completion.allCompleted) {
                console.log('🎉 All workers completed!');
                clearInterval(monitor);
                this.terminate();
            }
        }, intervalMs);

        return monitor;
    }

    terminate() {
        console.log('Terminating all workers...');
        
        for (const [workerId, worker] of this.workers) {
            if (!worker.process.killed) {
                worker.process.kill('SIGTERM');
                console.log(`Terminated Worker ${workerId}`);
            }
        }

        this.workers.clear();
        console.log('All workers terminated.');
    }
}

// Main execution
async function main() {
    if (process.argv.length < 3) {
        console.log('Usage: node parallel_claude_runner.js <worker1_instructions.md> [worker2_instructions.md] ...');
        process.exit(1);
    }

    const instructionFiles = process.argv.slice(2);
    const runner = new ParallelClaudeRunner(process.cwd(), instructionFiles.length);

    console.log('🚀 Starting Parallel Claude CLI Execution');
    console.log(`Working Directory: ${process.cwd()}`);
    console.log(`Instruction Files: ${instructionFiles.join(', ')}`);
    console.log('');

    try {
        await runner.startAllWorkers(instructionFiles);
        
        // Start monitoring
        const monitor = await runner.monitorWorkers();

        // Handle graceful shutdown
        process.on('SIGINT', () => {
            console.log('\n🛑 Received SIGINT, shutting down...');
            clearInterval(monitor);
            runner.terminate();
            process.exit(0);
        });

        process.on('SIGTERM', () => {
            console.log('\n🛑 Received SIGTERM, shutting down...');
            clearInterval(monitor);
            runner.terminate();
            process.exit(0);
        });

    } catch (error) {
        console.error('Error running parallel Claude CLI:', error);
        runner.terminate();
        process.exit(1);
    }
}

// Run if called directly
if (require.main === module) {
    main().catch(console.error);
}

module.exports = ParallelClaudeRunner;