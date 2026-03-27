# Service Tracker — DevOps Learning Progress

**Updated:** 2026-03-27
**Project goal:** Build hands-on AWS/DevOps skills to work confidently on production stack (EKS, RDS, RabbitMQ, Redis, MongoDB, ALB, GitLab CI/CD).

---

## AWS Services

### Networking & Connectivity

| Service | Status | Phase | Notes |
|---------|--------|-------|-------|
| VPC | ✅ Done | Phase 3 | Reused existing VMo VPC (vpc-0120771daf2f1aea3) |
| Public/Private Subnets | ✅ Done | Phase 3 | 2 AZ: vmo-public-1a/1b, vmo-private-1a/1b |
| Internet Gateway | ✅ Done | Phase 3 | igw-028fff24dd81ecf41 |
| NAT Gateway | ✅ Done | Phase 3 | Xóa/tạo lại hàng ngày để tiết kiệm chi phí |
| Route Tables | ✅ Done | Phase 3 | vmo-private-rt → NAT; public RT → IGW |
| Security Groups | ✅ Done | Phase 4 | ALB SG (80/443), ECS SG (5000 from ALB), RDS SG (5432 from ECS) |
| Elastic IP | ✅ Done | Phase 3 | 3 EIPs: 2 cho ALB, 1 cho NAT |
| ALB (Application Load Balancer) | ✅ Done | Phase 4 | Internet-facing, 2 AZ, Target Group HTTP/5000 |
| Route 53 | ❌ Not yet | Phase 5+ | DNS management, custom domain |
| ACM (Certificate Manager) | ❌ Not yet | Phase 5+ | TLS/HTTPS termination tại ALB |
| API Gateway | ❌ Not yet | Phase 6 | Production stack dùng cho Kong/Super App |
| CloudFront | ❌ Not yet | Phase 6 | CDN, không dùng trong production hiện tại |
| Direct Connect | ❌ Not yet | — | Kết nối dedicated network — production yêu cầu |

### Compute & Container

| Service | Status | Phase | Notes |
|---------|--------|-------|-------|
| EC2 (basics) | ✅ Done | Phase 3 | bootstrap-vmo (t3.medium) — SSH debug |
| ECS Fargate | ✅ Done | Phase 4 | Cluster claude-demo, Service claude-demo-svc |
| ECR | ✅ Done | Phase 3 | 028668155772.dkr.ecr.ap-southeast-1.amazonaws.com/claude-demo |
| EKS (Kubernetes) | ❌ Not yet | Phase 5 | **Production target** — thay thế ECS |
| Lambda | ❌ Not yet | Phase 6 | Event-driven, không trong scope hiện tại |
| EBS | ⚠️ Partial | Phase 3 | Dùng ngầm với EC2, chưa tự cấu hình |
| Auto Scaling | ❌ Not yet | Phase 5 | ECS service auto scaling, EKS node groups |

### Database & Cache

| Service | Status | Phase | Notes |
|---------|--------|-------|-------|
| RDS PostgreSQL | ✅ Done | Phase 4 | claude-demo-db (db.t3.micro), Single-AZ, 20 GB |
| Secrets Manager | ✅ Done | Phase 3 | claude-demo/db-password + RDS auto-rotate secret |
| ElastiCache (Redis) | ❌ Not yet | Phase 5 | **Production target** — cache layer |
| DocumentDB (MongoDB) | ❌ Not yet | Phase 6 | **Production target** — NoSQL |
| Amazon MQ (RabbitMQ) | ❌ Not yet | Phase 6 | **Production target** — message queue |
| OpenSearch (ElasticSearch) | ❌ Not yet | Phase 6 | Production dùng cho search + log |
| DynamoDB | ❌ Not yet | Phase 5 | Dùng cho Terraform state locking |

### CI/CD & DevOps

| Service | Status | Phase | Notes |
|---------|--------|-------|-------|
| IAM Roles & Policies | ✅ Done | Phase 3 | github-actions-claude-demo, ecsTaskExecutionRole |
| OIDC Identity Provider | ✅ Done | Phase 3 | GitHub Actions → AWS không cần static key |
| GitHub Actions | ✅ Done | Phase 2-4 | test → build-and-push-ecr → deploy-ecs |
| GitLab CI/CD | ❌ Not yet | Phase 5 | **Company uses GitLab** — cần học để apply thực tế |
| Terraform | ❌ Not yet | Phase 5 | IaC thay thế manual Console — planned next |
| S3 (Terraform state) | ❌ Not yet | Phase 5 | Backend cho Terraform state |
| DynamoDB (state lock) | ❌ Not yet | Phase 5 | Terraform state locking |

### Observability & Security

| Service | Status | Phase | Notes |
|---------|--------|-------|-------|
| CloudWatch Logs | ⚠️ Partial | Phase 4 | ECS task logs tự động → /ecs/claude-demo |
| CloudWatch Alarms | ❌ Not yet | Phase 6 | CPU, memory, pod restart alerts |
| CloudWatch Dashboards | ❌ Not yet | Phase 6 | Metrics visualization |
| Security Hub | ❌ Not yet | Phase 6 | Production yêu cầu, có security gap cần fix |
| AWS Config | ❌ Not yet | Phase 6 | Audit config changes |
| AWS WAF | ❌ Not yet | Phase 6 | Production dùng Cloudflare WAF |
| GuardDuty | ❌ Not yet | Phase 6 | Threat detection |

---

## Kubernetes / Container Orchestration

| Topic | Status | Phase | Notes |
|-------|--------|-------|-------|
| Docker multi-stage build | ✅ Done | Phase 1 | python:3.12-slim, non-root user, HEALTHCHECK |
| Docker HEALTHCHECK | ✅ Done | Phase 1 | Dùng Python urllib (không có curl trong slim) |
| ECS Task Definition | ✅ Done | Phase 4 | 0.25 vCPU / 512 MB, Fargate, Secrets injection |
| ECS Service (rolling update) | ✅ Done | Phase 4 | --force-new-deployment |
| Helm Charts | ❌ Not yet | Phase 5 | Package K8s app |
| K8s Deployment | ❌ Not yet | Phase 5 | — |
| K8s StatefulSet | ❌ Not yet | Phase 5 | Cho stateful workloads (DB, cache) |
| K8s DaemonSet | ❌ Not yet | Phase 6 | Log agents, monitoring agents |
| K8s Service / Ingress | ❌ Not yet | Phase 5 | ALB Ingress Controller trên EKS |
| K8s HPA (autoscaling) | ❌ Not yet | Phase 5 | Scale theo CPU/memory |
| K8s PVC/PV | ❌ Not yet | Phase 5 | Persistent storage |
| K8s ConfigMap / Secret | ❌ Not yet | Phase 5 | Config management |
| K8s Namespace | ❌ Not yet | Phase 5 | Environment isolation |
| K8s Liveness/Readiness Probe | ❌ Not yet | Phase 5 | Health checking |
| K8s Rolling Update / Rollback | ❌ Not yet | Phase 5 | — |
| K8s Resource Limits | ❌ Not yet | Phase 5 | requests/limits per container |
| ArgoCD / GitOps | ❌ Not yet | Phase 5+ | Tách app repo, infra repo, manifest repo |

---

## Observability Stack (non-AWS)

| Tool | Status | Phase | Notes |
|------|--------|-------|-------|
| Prometheus | ❌ Not yet | Phase 6 | Metrics scraping |
| Grafana | ❌ Not yet | Phase 6 | Dashboards |
| Loki | ❌ Not yet | Phase 6 | Log aggregation |
| ELK / EFK Stack | ❌ Not yet | Phase 6 | Production dùng OpenSearch |

---

## Production Stack Alignment

Mapping giữa những gì tôi đã học và production stack thực tế (VinMotion RMS):

| Production Component | AWS Service | Practice Status |
|---------------------|-------------|-----------------|
| Kubernetes cluster | EKS | ❌ Not yet |
| PostgreSQL | RDS | ✅ Done |
| Redis cache | ElastiCache | ❌ Not yet |
| MongoDB | DocumentDB | ❌ Not yet |
| RabbitMQ | Amazon MQ | ❌ Not yet |
| ElasticSearch/OpenSearch | OpenSearch | ❌ Not yet |
| Docker image registry | ECR | ✅ Done |
| GitLab CI/CD | GitLab CI | ❌ Not yet (dùng GitHub Actions) |
| Load balancer | ALB | ✅ Done |
| Secret management | Secrets Manager | ✅ Done |
| Networking | VPC/Subnet/SG | ✅ Done |
| DNS | Route 53 | ❌ Not yet |
| TLS/HTTPS | ACM | ❌ Not yet |
| Object storage | S3 | ❌ Not yet |
| IaC | Terraform | ❌ Not yet |
| WAF/DDoS | Cloudflare → AWS WAF | ❌ Not yet |
| Monitoring | CloudWatch → Prometheus | ⚠️ Partial |

---

## Summary

| Category | Done | In Progress | Not Yet |
|----------|------|-------------|---------|
| AWS Networking | 7 | 0 | 6 |
| AWS Compute/Container | 3 | 1 | 4 |
| AWS Database/Cache | 2 | 0 | 5 |
| AWS CI/CD & IaC | 4 | 0 | 4 |
| AWS Observability/Security | 1 | 1 | 5 |
| Kubernetes | 3 | 0 | 14 |
| Observability Stack | 0 | 0 | 4 |
| **Total** | **20** | **2** | **42** |

**Next priority (Phase 5):** Terraform → S3 state → EKS → Helm → GitLab CI/CD
