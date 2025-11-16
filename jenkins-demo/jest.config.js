module.exports = {
    testEnvironment: 'node',
    coverageDirectory: 'coverage',
    collectCoverageFrom: [
        '*.js',
        '!*.test.js',
        '!jest.config.js',
        '!coverage/**'
    ],
    testMatch: [
        '**/*.test.js'
    ],
    coverageThreshold: {
        global: {
            branches: 60,
            functions: 70,
            lines: 80,
            statements: 80
        }
    },
    coverageReporters: [
        'text',
        'lcov',
        'html'
    ]
};
