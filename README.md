# ecom-advanced-cicd

Advanced CI/CD demo repository for a Node.js e-commerce sample.
Contains app code, Dockerfile, Jenkins pipeline, Terraform for ECS (blue/green), and deploy scripts.

See directories:
- app/ (Node.js app + tests)
- docker/ (Dockerfile, .dockerignore)
- jenkins/ (Jenkinsfile + deploy scripts)
- terraform-ecs/ (Terraform to create ALB + ECS Fargate blue/green)
- .gitignore
