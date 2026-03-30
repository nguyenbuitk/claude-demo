# Runbook — project-1

## Quick Reference

| Resource | Value |
|----------|-------|
| ALB | `project-1-dev-alb-856207708.ap-southeast-1.elb.amazonaws.com` |
| ECS Cluster | `project-1-dev-cluster` |
| ECS Service | `project-1-dev-svc` |
| RDS | `project-1-dev-db` |
| CloudWatch Logs | `/ecs/project-1-dev` |
| Region | `ap-southeast-1` |

---

## 1. Service Down (app không response)

**Triệu chứng:** `curl http://<alb>/health` timeout hoặc 5xx

**Bước 1 — Kiểm tra ECS tasks:**
```bash
aws ecs describe-services \
  --cluster project-1-dev-cluster \
  --services project-1-dev-svc \
  --region ap-southeast-1 \
  --query "services[0].{Running:runningCount,Desired:desiredCount,Pending:pendingCount}"
```

**Bước 2 — Xem lý do task stopped:**
```bash
# List stopped tasks
aws ecs list-tasks \
  --cluster project-1-dev-cluster \
  --desired-status STOPPED \
  --region ap-southeast-1

# Xem chi tiết task bị stop (thay <task-arn>)
aws ecs describe-tasks \
  --cluster project-1-dev-cluster \
  --tasks <task-arn> \
  --region ap-southeast-1 \
  --query "tasks[0].containers[0].{Reason:reason,Status:lastStatus,ExitCode:exitCode}"
```

**Bước 3 — Xem logs:**
```bash
aws logs tail /ecs/project-1-dev --since 30m --region ap-southeast-1
```

**Bước 4 — Force redeploy:**
```bash
aws ecs update-service \
  --cluster project-1-dev-cluster \
  --service project-1-dev-svc \
  --force-new-deployment \
  --region ap-southeast-1
```

---

## 2. DB Fail (app không kết nối được RDS)

**Triệu chứng:** Logs có `connection refused` hoặc `could not connect to server`

**Bước 1 — Kiểm tra RDS status:**
```bash
aws rds describe-db-instances \
  --db-instance-identifier project-1-dev-db \
  --region ap-southeast-1 \
  --query "DBInstances[0].{Status:DBInstanceStatus,Endpoint:Endpoint.Address}"
```

**Bước 2 — Nếu RDS stopped, start lại:**
```bash
aws rds start-db-instance \
  --db-instance-identifier project-1-dev-db \
  --region ap-southeast-1
```

**Bước 3 — Kiểm tra Secret còn đúng không:**
```bash
aws secretsmanager get-secret-value \
  --secret-id project-1-dev-db-credentials \
  --region ap-southeast-1 \
  --query "SecretString" --output text
```

**Bước 4 — Kiểm tra Security Group:**
ECS SG phải có inbound rule port 5432 từ ECS SG.
```bash
aws ec2 describe-security-groups \
  --region ap-southeast-1 \
  --filters "Name=group-name,Values=project-1-dev-rds-sg" \
  --query "SecurityGroups[0].IpPermissions"
```

---

## 3. High CPU (ECS CPU > 80%)

**Triệu chứng:** CloudWatch alarm trigger, email alert nhận được

**Bước 1 — Xem CPU hiện tại:**
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ClusterName,Value=project-1-dev-cluster \
               Name=ServiceName,Value=project-1-dev-svc \
  --start-time $(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average \
  --region ap-southeast-1
```

**Bước 2 — Scale up tạm thời (thêm task):**
```bash
aws ecs update-service \
  --cluster project-1-dev-cluster \
  --service project-1-dev-svc \
  --desired-count 2 \
  --region ap-southeast-1
```

**Bước 3 — Xem logs tìm request gây spike:**
```bash
aws logs filter-log-events \
  --log-group-name /ecs/project-1-dev \
  --start-time $(date -d '30 minutes ago' +%s000) \
  --region ap-southeast-1
```

**Bước 4 — Scale về sau khi xử lý:**
```bash
aws ecs update-service \
  --cluster project-1-dev-cluster \
  --service project-1-dev-svc \
  --desired-count 1 \
  --region ap-southeast-1
```

---

## 4. CloudWatch Logs Query (Insights)

```
# Tất cả errors trong 1 giờ qua
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 50

# Request chậm > 1s
fields @timestamp, @message
| filter @message like /GET|POST/
| sort @timestamp desc
```

Console: https://ap-southeast-1.console.aws.amazon.com/cloudwatch/home#logsV2:log-groups/log-group/$252Fecs$252Fproject-1-dev
