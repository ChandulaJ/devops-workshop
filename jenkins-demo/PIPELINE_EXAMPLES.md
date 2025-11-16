# Jenkinsfile Examples

This directory contains different Jenkinsfile examples for various use cases.

## Basic Pipeline (Jenkinsfile)
The main Jenkinsfile with all standard stages including Docker build and deployment.

## Simplified Pipeline
A minimal version for beginners:

```groovy
pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Install') {
            steps {
                sh 'npm install'
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm test'
            }
        }
    }
}
```

## With Parallel Stages
Example with parallel execution:

```groovy
stage('Quality Checks') {
    parallel {
        stage('Lint') {
            steps {
                sh 'npm run lint'
            }
        }
        stage('Security Scan') {
            steps {
                sh 'npm audit'
            }
        }
    }
}
```

## Advanced Features to Explore

1. **Parameters**: Accept user input
2. **Triggers**: Automated builds
3. **Credentials**: Secure secret management
4. **Notifications**: Slack, email integration
5. **Artifacts**: Archive build outputs
