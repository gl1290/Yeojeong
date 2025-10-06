/**
 * Sample background worker service
 * This demonstrates a long-running process that could handle background tasks
 */

let isRunning = true;
let taskCount = 0;

// Graceful shutdown handler
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully...');
    isRunning = false;
});

process.on('SIGINT', () => {
    console.log('SIGINT received, shutting down gracefully...');
    isRunning = false;
});

// Simulated task processing
async function processTask() {
    taskCount++;
    console.log(`Processing task #${taskCount} at ${new Date().toISOString()}`);
    
    // Simulate some work
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    console.log(`Task #${taskCount} completed`);
}

// Main worker loop
async function run() {
    console.log('Worker started');
    console.log(`Environment: ${process.env.ENVIRONMENT || 'dev'}`);
    console.log(`Version: ${process.env.GIT_COMMIT || 'unknown'}`);
    
    while (isRunning) {
        try {
            await processTask();
            
            // Wait before next task
            await new Promise(resolve => setTimeout(resolve, 10000));
        } catch (error) {
            console.error('Error processing task:', error);
            // Wait before retrying
            await new Promise(resolve => setTimeout(resolve, 30000));
        }
    }
    
    console.log('Worker stopped gracefully');
    process.exit(0);
}

// Start the worker
run().catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
});
