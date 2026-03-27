# Phase 3 — AWS Networking + Registry

**Goal:** ECR, OIDC, IAM, ECS Cluster sẵn sàng — CI/CD push image lên ECR qua GitHub Actions
**Branch:** `gsd/phase-03-aws-networking-registry`
**AWS Region:** ap-southeast-1 | Account: 028668155772
**Completed:** 2026-03-25

## Progress

| Step | Resource | Status |
|------|----------|--------|
| 1 | NAT Gateway + Route Table | ✅ Done (2026-03-25) |
| 2 | ECR Repository | ✅ Done (2026-03-25) |
| 3 | OIDC Provider | ✅ Done (2026-03-25) |
| 4 | IAM Role (github-actions-claude-demo) | ✅ Done (2026-03-25) |
| 5 | ECS Cluster | ✅ Done (2026-03-25) |
| 6 | Secrets Manager | ✅ Done (2026-03-25) |
| 7 | Update ci.yml (build-and-push-ecr job) | ✅ Done (2026-03-25) |

## Key Values

```
VPC             : vpc-0120771daf2f1aea3 (VMo, 10.0.0.0/16)
Public subnets  : subnet-0cf9522c9c38535bd (vmo-public-1a)
                  subnet-0020b40a7df8faf3d (vmo-public-1b)
Private subnets : subnet-04325cd1624327a16 (vmo-private-1a)
                  subnet-060604d39d5de044e (vmo-private-1b)
Internet GW     : igw-028fff24dd81ecf41

NAT Gateway     : nat-0a949df919e2b23ac (vmo-public-1a) — recreated daily
EIP (NAT)       : 47.131.109.34 (eipalloc-07b05a4db6dd3f969)
Private RT      : rtb-00516c7f54fb6520d (vmo-private-rt)

ECR             : 028668155772.dkr.ecr.ap-southeast-1.amazonaws.com/claude-demo
OIDC Provider   : token.actions.githubusercontent.com
IAM Role        : github-actions-claude-demo
ECS Cluster     : claude-demo (Fargate)
Secret          : claude-demo/db-password
```

---

## Step 1: NAT Gateway + Route Table ✅

**Kết quả thực tế:**
- EIP: `47.131.109.34` (eipalloc-07b05a4db6dd3f969)
- NAT Gateway trong `vmo-public-1a`
- Route table `vmo-private-rt`: `0.0.0.0/0` → NAT Gateway

**Console steps:**
1. **VPC → Elastic IPs → Allocate Elastic IP address** → Allocate
2. **VPC → NAT Gateways → Create NAT gateway**
   - Name: `vmo-nat-1a`
   - Subnet: `vmo-public-1a (subnet-0cf9522c9c38535bd)`
   - Connectivity type: Public
   - Elastic IP: chọn EIP vừa tạo
   - → Create (chờ ~2 phút → Available)
3. **VPC → Route tables** → tìm route table của private subnets
   - Edit routes → Add route: `0.0.0.0/0` → NAT Gateway `vmo-nat-1a`
   - → Save changes

> ⚠️ NAT Gateway bị xóa cuối ngày để tiết kiệm chi phí ($1.42/ngày). Script resume trong `aws-resources.md`.

---

## Step 2: ECR Repository ✅

**Kết quả thực tế:**
- URI: `028668155772.dkr.ecr.ap-southeast-1.amazonaws.com/claude-demo`
- Scan on push: ✅ | Tag immutability: Disabled | Encryption: AES-256

**Console steps:**
1. **ECR → Repositories → Create repository**
   - Visibility: Private
   - Repository name: `claude-demo`
   - Tag immutability: Disabled (mutable)
   - Image scan settings: bật **Scan on push** ✓
   - Encryption: AES-256 (default)
   - → Create repository

---

## Step 3: OIDC Provider ✅

**Kết quả thực tế:**
- Provider URL: `https://token.actions.githubusercontent.com`
- Audience: `sts.amazonaws.com`

**Console steps:**
1. **IAM → Identity providers → Add provider**
   - Provider type: OpenID Connect
   - Provider URL: `https://token.actions.githubusercontent.com`
   - → Click **Get thumbprint**
   - Audience: `sts.amazonaws.com`
   - → Add provider

---

## Step 4: IAM Role github-actions-claude-demo ✅

**Kết quả thực tế:**
- Trusted entity: GitHub Actions OIDC (`repo:nguyenbuitk/claude-demo:*`)
- Inline policy: `claude-demo-ci-policy`

**Console steps:**
1. **IAM → Roles → Create role**
   - Trusted entity type: **Web identity**
   - Identity provider: `token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`
   - GitHub organization: `nguyenbuitk`
   - GitHub repository: `claude-demo`
   - → Next → Next
   - Role name: `github-actions-claude-demo`
   - → Create role

2. Click vào role → **Permissions → Add permissions → Create inline policy** → JSON:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRAuth",
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    },
    {
      "Sid": "ECRPush",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:BatchGetImage",
        "ecr:DescribeRepositories"
      ],
      "Resource": "arn:aws:ecr:ap-southeast-1:028668155772:repository/claude-demo"
    },
    {
      "Sid": "ECSUpdate",
      "Effect": "Allow",
      "Action": [
        "ecs:UpdateService",
        "ecs:DescribeServices",
        "ecs:RegisterTaskDefinition",
        "ecs:DescribeTaskDefinition"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMPassRole",
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "arn:aws:iam::028668155772:role/ecsTaskExecutionRole"
    }
  ]
}
```

- Policy name: `claude-demo-ci-policy` → Create policy

---

## Step 5: ECS Cluster ✅

**Kết quả thực tế:**
- Cluster name: `claude-demo`
- Infrastructure: Fargate (serverless)

**Console steps:**
1. **ECS → Clusters → Create cluster**
   - Cluster name: `claude-demo`
   - Infrastructure: tích **AWS Fargate (serverless)** ✓ (bỏ EC2, bỏ External)
   - Tags: `project=claude-demo`
   - → Create

---

## Step 6: Secrets Manager ✅

**Kết quả thực tế:**
- Secret name: `claude-demo/db-password`
- Key: `password` | Value: placeholder (thay bằng real password ở Phase 4)
- RDS-managed secret (tự rotate) được tạo riêng khi tạo RDS ở Phase 4

**Console steps:**
1. **Secrets Manager → Store a new secret**
   - Secret type: Other type of secret
   - Key/value: `password` = `PLACEHOLDER_CHANGE_BEFORE_PHASE4`
   - Encryption key: `aws/secretsmanager` (default)
   - → Next
   - Secret name: `claude-demo/db-password`
   - Description: RDS PostgreSQL password for claude-demo
   - → Next → Next → Store

---

## Step 7: Update ci.yml ✅

**Kết quả thực tế** — thêm job `build-and-push-ecr` vào `.github/workflows/ci.yml`:

```yaml
  build-and-push-ecr:
    needs: [test]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@v4
      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::028668155772:role/github-actions-claude-demo
          aws-region: ap-southeast-1
      - name: Log in to ECR
        uses: aws-actions/amazon-ecr-login@v2
      - name: Build and push to ECR
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: |
            028668155772.dkr.ecr.ap-southeast-1.amazonaws.com/claude-demo:latest
            028668155772.dkr.ecr.ap-southeast-1.amazonaws.com/claude-demo:sha-${{ github.sha }}
```

---

## Verify Checklist

- [x] NAT Gateway available → private subnet có internet access
- [x] ECR repo `claude-demo` tồn tại với scanOnPush=true
- [x] OIDC Provider `token.actions.githubusercontent.com` tồn tại
- [x] IAM Role `github-actions-claude-demo` với đúng trust policy
- [x] ECS Cluster `claude-demo` (Fargate) ready
- [x] Push to main → CI `build-and-push-ecr` job pass
- [x] Image xuất hiện tại ECR với tags `:latest` + `:sha-xxx`
