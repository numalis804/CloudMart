# CloudMart

A cloud-native e-commerce reference architecture demonstrating production-ready DevOps practices on AWS.

## 🏗️ Architecture

Modern microservices architecture deployed on Amazon EKS with full CI/CD automation.

### Tech Stack
- **Cloud Provider**: AWS (EKS, RDS, ElastiCache, S3, CloudFront)
- **Infrastructure as Code**: Terraform
- **Container Orchestration**: Kubernetes (Amazon EKS)
- **CI/CD**: GitHub Actions + ArgoCD
- **Monitoring**: Prometheus + Grafana
- **Security**: AWS WAF, Cognito, GuardDuty

## 🚀 Project Status

**Phase**: Initial Setup  
**Current Step**: 0.3 - Repository Setup

## 📁 Project Structure
```
CloudMart/
├── .github/workflows/    # CI/CD pipelines
├── terraform/            # Infrastructure as Code
├── k8s/                  # Kubernetes manifests
├── helm-charts/          # Custom Helm charts
├── microservices/        # Application source code
├── docs/                 # Documentation
└── scripts/              # Automation scripts
```

## 🛠️ Prerequisites

- Ubuntu on WSL2
- AWS CLI v2
- Terraform >= 1.5
- kubectl >= 1.26
- Helm v3
- Docker
- k6

## 📚 Documentation

Detailed documentation available in `/docs`:
- Setup guide
- Architecture decisions
- Deployment procedures
- Security model
- Monitoring and observability

## 🔐 Security

- No credentials committed to repository
- All secrets managed via AWS Secrets Manager
- Infrastructure encrypted at rest and in transit
- Regular security scanning with Trivy and tfsec

## 📝 License

This project is created for portfolio and educational purposes.

## �� Author

**Your Emanuele Lisetti**  
Portfolio: [portfolio-url]  
LinkedIn: [linkedin-url]  
GitHub: [@numalis804](https://github.com/numalis804)
