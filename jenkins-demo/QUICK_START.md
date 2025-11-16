# Jenkins CI/CD Demo - Quick Reference Guide

## 🚀 Quick Commands

### Local Development
```bash
npm install          # Install dependencies
npm start           # Run application
npm test            # Run tests
npm run lint        # Check code style
```

### Docker
```bash
docker build -t jenkins-cicd-demo .
docker run -p 3000:3000 jenkins-cicd-demo
docker-compose up -d
```

## 📋 Pipeline Stages Overview

1. **Checkout** - Get source code
2. **Environment Setup** - Verify tools
3. **Install Dependencies** - npm ci
4. **Lint Code** - Code quality check
5. **Run Tests** - Execute test suite
6. **Build Docker Image** - Create container
7. **Test Docker Image** - Verify container works
8. **Deploy** - Deploy to environments

## 🎯 Key Learning Points

- **CI/CD Pipeline**: Automated build, test, and deploy
- **Jenkins**: Pipeline as Code with Jenkinsfile
- **Docker**: Containerization for consistency
- **Testing**: Automated quality assurance
- **DevOps**: Integration of development and operations

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| Port in use | `lsof -i :3000` then `kill -9 <PID>` |
| npm install fails | `npm cache clean --force` |
| Docker permission | `sudo usermod -aG docker $USER` |
| Tests fail | Check `app.test.js` for errors |

## 📊 Expected Pipeline Flow

```
Checkout → Setup → Dependencies → Lint → Test → Build → Test Image → Deploy
   ✓         ✓          ✓          ✓      ✓      ✓         ✓          ✓
```

## 🎓 Student Exercises

1. **Beginner**: Add a new endpoint and test
2. **Intermediate**: Add environment-specific config
3. **Advanced**: Implement blue-green deployment

## 📞 Endpoints

- `http://localhost:3000/` - Homepage
- `http://localhost:3000/health` - Health check
- `http://localhost:3000/api/info` - App info

---
**For full documentation, see README.md**
