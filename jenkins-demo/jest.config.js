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
            branches: 70,
            functions: 70,
            lines: 70,
            statements: 70
        }
    },
    coverageReporters: [
        'text',
        'lcov',
        'html'
    ],
    reporters: [
        'default',
        ['jest-junit', {
            outputDirectory: '.',
            outputName: 'junit.xml',
        }]
    ]
};
