# Phase 4 — ECS Fargate + RDS + ALB

**Goal:** `curl http://<alb-dns>/health` → `{"status": "ok"}` HTTP 200
**Branch:** `gsd/phase-04-ecs-fargate-rds-alb`
**AWS Region:** ap-southeast-1 | Account: 028668155772

## Progress

| Step | Resource | Status |
|------|----------|--------|
| 1 | RDS PostgreSQL | ✅ Done (2026-03-25) |
| 2 | ECS Task Definition | ○ |
| 3 | ECS Service | ○ |
| 4 | ALB + Target Group + Listener | ○ |
| 5 | Update ci.yml (deploy-ecs job) | ○ |
| 6 | Migrate storage.py → PostgreSQL | ○ |

## Key Values (dùng cho các steps sau)

```
VPC             : vpc-0120771daf2f1aea3 (VMo)
Public subnets  : subnet-0cf9522c9c38535bd (vmo-public-1a)
                  subnet-0020b40a7df8faf3d (vmo-public-1b)
Private subnets : subnet-04325cd1624327a16 (vmo-private-1a)
                  subnet-060604d39d5de044e (vmo-private-1b)
SG - ALB        : sg-0166254711a3b5ae5 (vmo-alb-sg)
SG - ECS        : sg-01374c41c25a9809f (vmo-eks-sg)
SG - DB         : sg-0a6cc925b46fce8bf (vmo-db-sg)

DB Endpoint     : claude-demo-db.cdouj2djsuhw.ap-southeast-1.rds.amazonaws.com
DB Port         : 5432
DB Name         : claude_demo
DB Username     : claude_admin
DB Secret ARN   : arn:aws:secretsmanager:ap-southeast-1:028668155772:secret:rds!db-2d340a22-95f2-4b24-905a-f1c37ba4e82d-a2v8eW

ECR Image       : 028668155772.dkr.ecr.ap-southeast-1.amazonaws.com/claude-demo:latest
ECS Cluster     : claude-demo
```

---

## Step 1: RDS PostgreSQL ✅

**Kết quả thực tế:**
- Instance ID: `claude-demo-db`
- Engine: PostgreSQL 17.6
- Class: db.t3.micro | Storage: 20 GB
- Subnet: vmo-private-1a (10.0.10.131) — private ✓
- Public access: No ✓
- Security group: `vmo-db-sg` ✓
- Secret: RDS-managed (tự rotate), chứa `username` + `password`

**Lưu ý:**
- Dùng RDS-managed secret ARN (ở trên) cho ECS Task Definition
- `host`, `port`, `dbname` truyền qua environment variable riêng (không có trong secret)

---

## Step 2: ECS Task Definition ○

1. Vào **ECS** → **Task definitions** → **Create new task definition**
   - Family name: `claude-demo`
   - Launch type: **Fargate**
   - CPU: `0.25 vCPU` | Memory: `0.5 GB`
   - Task role: `ecsTaskExecutionRole`
   - Execution role: `ecsTaskExecutionRole`

2. **Container:**
   - Name: `claude-demo`
   - Image URI: `028668155772.dkr.ecr.ap-southeast-1.amazonaws.com/claude-demo:latest`
   - Port mappings: `5000` (TCP)

3. **Environment variables** (plain text):
   | Key | Value |
   |-----|-------|
   | `DB_HOST` | `claude-demo-db.cdouj2djsuhw.ap-southeast-1.rds.amazonaws.com` |
   | `DB_PORT` | `5432` |
   | `DB_NAME` | `claude_demo` |

4. **Secrets** (từ Secrets Manager → ValueFrom):
   | Key | Secret ARN |
   |-----|-----------|
   | `DB_USERNAME` | `arn:...:rds!db-2d340a22-...:username` |
   | `DB_PASSWORD` | `arn:...:rds!db-2d340a22-...:password` |

   > Full ARN: `arn:aws:secretsmanager:ap-southeast-1:028668155772:secret:rds!db-2d340a22-95f2-4b24-905a-f1c37ba4e82d-a2v8eW`

5. **Health check:**
   - Command: `CMD-SHELL, curl -f http://localhost:5000/health || exit 1`
   - Interval: 30s | Timeout: 5s | Retries: 3

6. → **Create**

---

## Step 3: ALB + Target Group ○

> Làm Step 3 trước Step 4 vì ECS Service cần chọn ALB khi tạo.

1. Vào **EC2** → **Load Balancers** → **Create load balancer** → **Application Load Balancer**
   - Name: `claude-demo-alb`
   - Scheme: **Internet-facing**
   - VPC: `VMo (vpc-0120771daf2f1aea3)`
   - Subnets: `vmo-public-1a`, `vmo-public-1b`
   - Security group: `vmo-alb-sg (sg-0166254711a3b5ae5)`

2. **Target Group** (tạo mới trong flow):
   - Type: **IP addresses**
   - Name: `claude-demo-tg`
   - Protocol: HTTP | Port: `5000`
   - VPC: `VMo`
   - Health check path: `/health`
   - Health check interval: 30s | Threshold: 2

3. **Listener:**
   - Protocol: HTTP | Port: `80`
   - Default action: Forward → `claude-demo-tg`

4. → **Create load balancer**
5. Lưu lại **DNS name**: `claude-demo-alb-xxxx.ap-southeast-1.elb.amazonaws.com`

---

## Step 4: ECS Service ○

1. Vào **ECS** → **Clusters** → `claude-demo` → **Services** → **Create**
   - Launch type: **Fargate**
   - Task definition: `claude-demo` (revision mới nhất)
   - Service name: `claude-demo-svc`
   - Desired tasks: `1`

2. **Networking:**
   - VPC: `VMo`
   - Subnets: `vmo-private-1a`, `vmo-private-1b`
   - Security group: `vmo-eks-sg (sg-01374c41c25a9809f)`
   - Public IP: **Disabled**

3. **Load balancing:**
   - Load balancer type: **Application Load Balancer**
   - Load balancer: `claude-demo-alb`
   - Container: `claude-demo:5000`
   - Target group: `claude-demo-tg`

4. → **Create**

5. Verify: `curl http://<alb-dns>/health` → `{"status": "ok"}`

---

## Step 5: Update ci.yml ○

Thêm job `deploy-ecs` vào `.github/workflows/ci.yml` sau job `build-and-push-ecr`:

```yaml
  deploy-ecs:
    needs: [build-and-push-ecr]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    steps:
      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::028668155772:role/github-actions-claude-demo
          aws-region: ap-southeast-1

      - name: Deploy to ECS
        run: |
          aws ecs update-service \
            --cluster claude-demo \
            --service claude-demo-svc \
            --force-new-deployment \
            --region ap-southeast-1
```

---

## Step 6: Migrate storage.py → PostgreSQL ○

Cần update app để đọc/ghi PostgreSQL thay vì JSON file:
- Thêm `psycopg2-binary` vào `requirements.txt`
- Update `storage.py`: thay `load_tasks()`/`save_tasks()` dùng PostgreSQL
- Tạo migration script tạo bảng `tasks`
- Test local với DB connection string

> Chi tiết sẽ bổ sung khi bắt đầu step này.

---

## Verify Checklist (sau khi xong tất cả)

- [ ] `curl http://<alb-dns>/health` → `{"status": "ok"}` HTTP 200
- [ ] Tạo task mới → lưu vào RDS (không phải JSON file)
- [ ] Merge to main → CI chạy → ECS rolling update
- [ ] ECS task fail health check → tự restart
- [ ] Không có AWS credential nào hardcode trong code
