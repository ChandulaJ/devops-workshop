const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.static('public'));

// Routes
app.get('/', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Jenkins CI/CD Demo</title>
            <style>
                body {
                    font-family: Arial, sans-serif;
                    max-width: 800px;
                    margin: 50px auto;
                    padding: 20px;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                }
                .container {
                    background: rgba(255, 255, 255, 0.1);
                    padding: 40px;
                    border-radius: 10px;
                    backdrop-filter: blur(10px);
                }
                h1 { margin-top: 0; }
                .badge {
                    display: inline-block;
                    padding: 5px 10px;
                    background: #4CAF50;
                    border-radius: 5px;
                    margin: 10px 5px;
                }
                code {
                    background: rgba(0, 0, 0, 0.3);
                    padding: 2px 6px;
                    border-radius: 3px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🚀 Jenkins CI/CD Pipeline Demo</h1>
                <p>Welcome to the DevOps Workshop demonstration application!</p>
                <div class="badge">✓ Build Successful</div>
                <div class="badge">✓ Tests Passed</div>
                <div class="badge">✓ Deployed</div>
                <h2>About This Demo</h2>
                <p>This is a simple Node.js application designed to demonstrate:</p>
                <ul>
                    <li>Automated builds with Jenkins</li>
                    <li>Continuous Integration/Continuous Deployment</li>
                    <li>Docker containerization</li>
                    <li>Automated testing</li>
                    <li>Pipeline as Code</li>
                </ul>
                <p><strong>Version:</strong> 1.0.0</p>
                <p><strong>Environment:</strong> ${process.env.NODE_ENV || 'development'}</p>
            </div>
        </body>
        </html>
    `);
});

app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

app.get('/api/info', (req, res) => {
    res.json({
        name: 'Jenkins CI/CD Demo App',
        version: '1.0.0',
        description: 'A sample application for learning Jenkins pipelines',
        author: 'DevOps Workshop'
    });
});

// Start server
if (require.main === module) {
    app.listen(port, () => {
        console.log(`🚀 Server running on http://localhost:${port}`);
        console.log(`📊 Health check available at http://localhost:${port}/health`);
    });
}

module.exports = app;
