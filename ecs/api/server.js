const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        environment: process.env.ENVIRONMENT || 'dev',
        version: process.env.GIT_COMMIT || 'unknown'
    });
});

// Sample API endpoint
app.get('/api/hello', (req, res) => {
    res.json({
        message: 'Hello from Yeojeong API!',
        timestamp: new Date().toISOString(),
        environment: process.env.ENVIRONMENT || 'dev'
    });
});

// Sample POST endpoint
app.post('/api/echo', (req, res) => {
    res.json({
        echo: req.body,
        timestamp: new Date().toISOString()
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: 'Not Found',
        path: req.path
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(500).json({
        error: 'Internal Server Error',
        message: err.message
    });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`API server running on port ${PORT}`);
    console.log(`Environment: ${process.env.ENVIRONMENT || 'dev'}`);
});
