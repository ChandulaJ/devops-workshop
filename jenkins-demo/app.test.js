const request = require('supertest');
const app = require('./app');

describe('Jenkins CI/CD Demo Application', () => {
    
    describe('GET /', () => {
        it('should return 200 OK', async () => {
            const response = await request(app).get('/');
            expect(response.status).toBe(200);
            expect(response.text).toContain('Jenkins CI/CD Pipeline Demo');
        });

        it('should contain deployment badges', async () => {
            const response = await request(app).get('/');
            expect(response.text).toContain('Build Successful');
            expect(response.text).toContain('Tests Passed');
            expect(response.text).toContain('Deployed');
        });
    });

    describe('GET /health', () => {
        it('should return health status', async () => {
            const response = await request(app).get('/health');
            expect(response.status).toBe(200);
            expect(response.body).toHaveProperty('status', 'healthy');
            expect(response.body).toHaveProperty('timestamp');
            expect(response.body).toHaveProperty('uptime');
        });

        it('should return valid timestamp', async () => {
            const response = await request(app).get('/health');
            const timestamp = new Date(response.body.timestamp);
            expect(timestamp).toBeInstanceOf(Date);
            expect(timestamp.getTime()).not.toBeNaN();
        });
    });

    describe('GET /api/info', () => {
        it('should return application info', async () => {
            const response = await request(app).get('/api/info');
            expect(response.status).toBe(200);
            expect(response.body).toHaveProperty('name');
            expect(response.body).toHaveProperty('version');
            expect(response.body).toHaveProperty('description');
        });

        it('should return correct version', async () => {
            const response = await request(app).get('/api/info');
            expect(response.body.version).toBe('1.0.0');
        });
    });

    describe('Error handling', () => {
        it('should return 404 for unknown routes', async () => {
            const response = await request(app).get('/unknown-route');
            expect(response.status).toBe(404);
        });
    });
});
