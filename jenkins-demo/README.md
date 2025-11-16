# Jenkins CI/CD Pipeline Demo 🚀

A comprehensive demonstration project for students learning DevOps, focusing on Jenkins CI/CD pipelines, Docker containerization, and automated testing.

## 📋 Table of Contents

- [Learning Objectives](#learning-objectives)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Jenkins Setup](#jenkins-setup)
- [Pipeline Stages Explained](#pipeline-stages-explained)
- [Docker Commands](#docker-commands)
- [Testing](#testing)
- [Deployment Strategies](#deployment-strategies)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)
- [Additional Resources](#additional-resources)

## 🎯 Learning Objectives

By working through this demo, students will learn:

1. **Continuous Integration/Continuous Deployment (CI/CD)**
   - Understanding pipeline stages
   - Automated testing and building
   - Deployment automation

2. **Jenkins**
   - Creating declarative pipelines
   - Pipeline as Code (Jenkinsfile)
   - Environment variables and credentials
   - Post-build actions

3. **Docker**
   - Building Docker images
   - Multi-stage builds
   - Docker Compose for orchestration
   - Container best practices

4. **Testing**
   - Unit testing with Jest
   - Code coverage reporting
   - Integration testing

5. **DevOps Best Practices**
   - Version control integration
   - Automated quality checks
   - Environment separation
   - Infrastructure as Code

## 📁 Project Structure

```
jenkins-demo/
├── app.js                      # Main application file
├── app.test.js                 # Test suite
├── package.json                # Node.js dependencies
├── Jenkinsfile                 # Jenkins pipeline definition
├── Dockerfile                  # Docker image definition
├── Dockerfile.multistage       # Optimized multi-stage Dockerfile
├── docker-compose.yml          # Docker Compose configuration
├── .dockerignore               # Docker ignore patterns
├── .gitignore                  # Git ignore patterns
├── .eslintrc.json             # ESLint configuration
├── jest.config.js             # Jest testing configuration
└── README.md                   # This file
```

## 🔧 Prerequisites

### Software Requirements

- **Node.js** (v16 or higher)
- **Docker** (v20.10 or higher)
- **Docker Compose** (v2.0 or higher)
- **Jenkins** (v2.400 or higher)
- **Git**

### Jenkins Plugins Required

Install these plugins in Jenkins:

1. **Docker Pipeline** - For Docker integration
2. **Pipeline** - For pipeline support
3. **Git Plugin** - For Git integration
4. **HTML Publisher** - For coverage reports
5. **JUnit** - For test reports
6. **Blue Ocean** (Optional) - For modern UI

## 🚀 Quick Start

### 1. Clone and Setup

```bash
# Navigate to the project directory
cd jenkins-demo

# Install dependencies
npm install

# Run the application locally
npm start
```

Visit: `http://localhost:3000`

### 2. Run Tests

```bash
# Run tests once
npm test

# Run tests in watch mode
npm run test:watch

# Run with coverage
npm test -- --coverage
```

### 3. Run with Docker

```bash
# Build Docker image
docker build -t jenkins-cicd-demo .

# Run container
docker run -p 3000:3000 jenkins-cicd-demo

# Or use Docker Compose
docker-compose up -d
```

## 🔨 Jenkins Setup

### Step 1: Install Jenkins

**Using Docker (Recommended for learning):**

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

**Access Jenkins:**
- URL: `http://localhost:8080`
- Get initial admin password:
  ```bash
  docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
  ```

### Step 2: Create a New Pipeline Job

1. Click **"New Item"**
2. Enter job name: `jenkins-cicd-demo`
3. Select **"Pipeline"**
4. Click **OK**

### Step 3: Configure the Pipeline

**Option A: Pipeline from SCM (Recommended)**

1. In the pipeline configuration, scroll to **"Pipeline"** section
2. Select **"Pipeline script from SCM"**
3. Choose **"Git"** as SCM
4. Enter your repository URL
5. Set **"Script Path"** to: `jenkins-demo/Jenkinsfile`
6. Save

**Option B: Direct Pipeline Script**

1. In the pipeline configuration, select **"Pipeline script"**
2. Copy the contents of `Jenkinsfile` into the script box
3. Save

### Step 4: Run the Pipeline

1. Click **"Build Now"**
2. Watch the pipeline execute through stages
3. View logs and reports

## 📊 Pipeline Stages Explained

### 1. **Checkout**
```groovy
stage('Checkout') {
    // Downloads source code from Git repository
    checkout scm
}
```
- Pulls latest code from repository
- Shows last commit information

### 2. **Environment Setup**
```groovy
stage('Environment Setup') {
    // Verifies Node.js and npm versions
    sh 'node --version'
}
```
- Validates build environment
- Displays build information

### 3. **Install Dependencies**
```groovy
stage('Install Dependencies') {
    // Installs npm packages
    sh 'npm ci'
}
```
- Uses `npm ci` for clean, reproducible installs
- Faster than `npm install`

### 4. **Lint Code**
```groovy
stage('Lint Code') {
    // Checks code quality
    sh 'npm run lint'
}
```
- Enforces code style standards
- Catches potential errors

### 5. **Run Tests**
```groovy
stage('Run Tests') {
    // Executes test suite
    sh 'npm test'
}
```
- Runs unit and integration tests
- Generates coverage reports
- Publishes test results

### 6. **Build Docker Image**
```groovy
stage('Build Docker Image') {
    // Creates Docker image
    docker.build("app:${BUILD_NUMBER}")
}
```
- Builds containerized application
- Tags with build number

### 7. **Test Docker Image**
```groovy
stage('Test Docker Image') {
    // Validates the built image
    sh 'curl http://localhost:3000/health'
}
```
- Spins up container
- Runs health checks
- Verifies functionality

### 8. **Deploy Stages**
```groovy
stage('Deploy to Production') {
    when { branch 'main' }
    // Deployment logic
}
```
- Conditional deployment based on branch
- Manual approval for production
- Environment-specific configurations

## 🐳 Docker Commands

### Basic Commands

```bash
# Build image
docker build -t jenkins-cicd-demo .

# Run container
docker run -d -p 3000:3000 --name demo-app jenkins-cicd-demo

# View logs
docker logs demo-app

# Stop container
docker stop demo-app

# Remove container
docker rm demo-app

# Remove image
docker rmi jenkins-cicd-demo
```

### Multi-stage Build

```bash
# Build using multi-stage Dockerfile
docker build -f Dockerfile.multistage -t jenkins-cicd-demo:optimized .

# Compare image sizes
docker images | grep jenkins-cicd-demo
```

### Docker Compose

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild and start
docker-compose up -d --build
```

## 🧪 Testing

### Running Tests Locally

```bash
# All tests
npm test

# With coverage
npm test -- --coverage

# Watch mode
npm run test:watch

# Specific test file
npm test -- app.test.js
```

### Test Structure

```javascript
describe('Application Tests', () => {
    it('should return 200 OK', async () => {
        const response = await request(app).get('/');
        expect(response.status).toBe(200);
    });
});
```

### Coverage Reports

After running tests with coverage:
- Open `coverage/index.html` in browser
- Jenkins publishes this automatically

## 🚀 Deployment Strategies

### 1. **Branch-based Deployment**

- `main` → Production
- `staging` → Staging environment
- `develop` → Development environment

### 2. **Environment Variables**

```groovy
environment {
    APP_ENV = 'production'
    DB_HOST = credentials('db-host')
}
```

### 3. **Manual Approval**

```groovy
input message: 'Deploy to Production?', ok: 'Deploy'
```

## 🔍 Troubleshooting

### Common Issues

**1. Jenkins can't find Docker**

```bash
# Give Jenkins user Docker permissions
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

**2. npm install fails**

```bash
# Clear npm cache
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

**3. Port already in use**

```bash
# Find process using port 3000
lsof -i :3000

# Kill process
kill -9 <PID>
```

**4. Docker build fails**

```bash
# Check Docker daemon
docker info

# Clean Docker system
docker system prune -a
```

## ✅ Best Practices

### 1. **Pipeline as Code**
- Store Jenkinsfile in repository
- Version control all configurations
- Use declarative syntax

### 2. **Security**
- Use Jenkins credentials store
- Never hardcode secrets
- Run containers as non-root user

### 3. **Docker**
- Use specific base image tags
- Implement health checks
- Multi-stage builds for optimization
- .dockerignore to reduce image size

### 4. **Testing**
- Write tests before deployment
- Maintain high code coverage (>80%)
- Automate all tests

### 5. **Monitoring**
- Implement health check endpoints
- Log appropriately
- Use structured logging

## 📚 Additional Resources

### Documentation
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Docker Documentation](https://docs.docker.com/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)

### Tutorials
- [Jenkins Pipeline Tutorial](https://www.jenkins.io/doc/book/pipeline/)
- [Docker for Beginners](https://docker-curriculum.com/)

### Tools
- [Blue Ocean](https://www.jenkins.io/projects/blueocean/) - Modern Jenkins UI
- [Jenkins X](https://jenkins-x.io/) - Cloud-native CI/CD

## 🎓 Exercises for Students

### Beginner Level
1. Modify the homepage to display your name
2. Add a new API endpoint `/api/version`
3. Write a test for the new endpoint
4. Run the pipeline and verify it passes

### Intermediate Level
1. Add environment-specific configuration
2. Implement a new deployment stage for QA environment
3. Add Slack/email notifications on build failure
4. Create a rollback mechanism

### Advanced Level
1. Implement blue-green deployment
2. Add security scanning stage (SonarQube, OWASP)
3. Set up multi-branch pipeline
4. Integrate with Kubernetes for deployment

## 📝 License

MIT License - Feel free to use this project for learning purposes.

## 🤝 Contributing

This is a learning project. Students are encouraged to:
- Fork the repository
- Experiment with changes
- Share improvements
- Ask questions

## 📞 Support

For questions or issues:
- Create an issue in the repository
- Consult the troubleshooting section
- Review Jenkins and Docker documentation

---

**Happy Learning! 🎉**

Remember: The best way to learn DevOps is by doing. Break things, fix them, and understand why they work.
