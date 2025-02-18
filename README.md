# IaC Challenge Project

## Architecture

### Development Environment
- 1 Web Server (Ubuntu)
- 1 Database Server (PostgreSQL)
- Separate public/private subnets

### Production Environment
- 2 Web Servers (Ubuntu)
- 1 Database Server (PostgreSQL)
- 1 Reverse Proxy
- Separate public/private subnets

## Infrastructure Components
- **VPC Configuration**: Separate subnets for web and database servers
- **State Management**: Remote state backend in versioned S3 bucket
- **CI/CD**: Jenkins pipeline with environment-specific deployments

## Branch Strategy
- 'main': Production environment
- 'development': Development environment
- 'feature/*': New features (require PR to development)
- 'hotfix/*': Emergency fixes (can merge to main)

## Pipeline Workflow

1. **Feature Branches**:
    - Terraform plan only
    - Create PR to development when ready

2. **Development Branch**:
    - Terraform plan
    - Approval required
    - Deploy to dev environment
    - Run smoke tests

3. **Main Branch**:
    -  Terraform plan
    - Approval required
    - Deploy to production
    - Run smoke tests

4. **Hotfix Branches**:
    - Terraform plan
    - Approval required
    - Deploy to production
    - Run smoke tests