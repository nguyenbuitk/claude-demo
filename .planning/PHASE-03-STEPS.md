Steps config Console Steps 

  

  --- 

  Step 1: NAT Gateway 

  1. Vào VPC → Elastic IPs → Allocate Elastic IP address → Allocate 

  2. Vào VPC → NAT gateways → Create NAT gateway 

    - Name: vmo-nat-1a 

    - Subnet: vmo-public-1a (subnet-0cf9522c9c38535bd) 

    - Connectivity type: Public 

    - Elastic IP: chọn EIP vừa tạo 

    - → Create NAT gateway (chờ ~2 phút đến status Available) 

  3. Vào VPC → Route tables → tìm route table của private subnets 

    - Click vào route table → tab Routes → Edit routes 

    - Add route: Destination 0.0.0.0/0, Target = NAT Gateway → chọn vmo-nat-1a 

    - → Save changes 

  

  --- 

  Step 2: ECR Repository 

  

  1. Vào ECR (Elastic Container Registry) → Repositories → Create repository 

    - Visibility: Private 

    - Repository name: claude-demo 

    - Tag immutability: Disabled (mutable) 

    - Image scan settings → bật Scan on push ✓ 

    - Encryption: AES-256 (default) 

    - → Create repository 

  2. Ghi lại URI: 028668155772.dkr.ecr.ap-southeast-1.amazonaws.com/claude-demo 

  

  --- 

  Step 3: OIDC Provider 

  

  1. Vào IAM → Identity providers → Add provider 

    - Provider type: OpenID Connect 

    - Provider URL: https://token.actions.githubusercontent.com 

    - → Click Get thumbprint 

    - Audience: sts.amazonaws.com 

    - → Add provider 

  

  --- 

  Step 4: IAM Role cho GitHub Actions 

  

  1. Vào IAM → Roles → Create role 

  2. Trusted entity type: Web identity 

    - Identity provider: token.actions.githubusercontent.com 

    - Audience: sts.amazonaws.com 

    - GitHub organization: nguyenbuitk 

    - GitHub repository: claude-demo 

    - GitHub branch: (để trống = allow all) 

    - → Next 

  3. Add permissions: bỏ qua bước này, chọn Next 

  4. Role name: github-actions-claude-demo 

    - → Create role 

  5. Sau khi tạo xong → click vào role → tab Permissions → Add permissions → Create inline policy 

    - Chọn tab JSON, paste nội dung sau: 

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

    - Policy name: claude-demo-ci-policy 

    - → Create policy 

  

  --- 

  Step 5: ECS Cluster 

  

  1. Vào ECS (Elastic Container Service) → Clusters → Create cluster 

    - Cluster name: claude-demo 

    - Infrastructure: tích AWS Fargate (serverless) ✓ 

    - (bỏ EC2, bỏ External) 

    - Tags: Key=project, Value=claude-demo 

    - → Create 

  

  --- 

  Step 6: Secrets Manager 

  

  1. Vào Secrets Manager → Store a new secret 

    - Secret type: Other type of secret 

    - Key/value: Key=password, Value=PLACEHOLDER_CHANGE_BEFORE_PHASE4 

    - Encryption key: aws/secretsmanager (default) 

    - → Next 

    - Secret name: claude-demo/db-password 

    - Description: RDS PostgreSQL password for claude-demo 

    - → Next → Next → Store 

  

  --- 

  Step 7: Update ci.yml (sau khi xong các bước trên) 

  

  Khi xong Steps 2-4, báo tôi biết — tôi sẽ update file .github/workflows/ci.yml để thêm job push lên ECR dùng OIDC. 

  

  --- 

  Checklist 

  

  ┌──────┬─────────────────────────────────────────┬────────┐ 

  │ Step │                Resource                 │ Status │ 

  ├──────┼─────────────────────────────────────────┼────────┤ 

  │ 1    │ NAT Gateway + route table               │ ○      │ 

  ├──────┼─────────────────────────────────────────┼────────┤ 

  │ 2    │ ECR repo claude-demo                    │ ○      │ 

  ├──────┼─────────────────────────────────────────┼────────┤ 

  │ 3    │ OIDC Provider                           │ ○      │ 

  ├──────┼─────────────────────────────────────────┼────────┤ 

  │ 4    │ IAM Role github-actions-claude-demo     │ ○      │ 

  ├──────┼─────────────────────────────────────────┼────────┤ 

  │ 5    │ ECS Cluster claude-demo                 │ ○      │ 

  ├──────┼─────────────────────────────────────────┼────────┤ 

  │ 6    │ Secrets Manager claude-demo/db-password │ ○      │ 

  ├──────┼─────────────────────────────────────────┼────────┤ 

  │ 7    │ Update ci.yml                           │ ○      │ 

  └──────┴─────────────────────────────────────────┴────────┘ 

  

❯ vẽ lại flow cac service sau khi trien khai xong phase 3. tôi muốn hiểu rõ hơn về luồng hoạt độn 