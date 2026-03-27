# ─── DB Subnet Group ─────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "this" {
  name       = "${var.app_name}-${var.env}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.app_name}-${var.env}-db-subnet-group"
  }
}

# ─── RDS PostgreSQL ───────────────────────────────────────────────────────────

resource "aws_db_instance" "this" {
  identifier        = "${var.app_name}-db"
  engine            = "postgres"
  engine_version    = "17"
  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_sg_id]

  storage_encrypted = true

  # Dev settings — không cần backup và multi-AZ
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0
  multi_az                = false

  tags = {
    Name = "${var.app_name}-${var.env}-db"
  }

  # Brownfield: ignore các thuộc tính khác với Phase-3 manual resources
  # vpc_security_group_ids: RDS ở VPC cũ, không thể dùng SG từ Terraform VPC mới
  # db_subnet_group_name: RDS đang dùng subnet group tạo tay
  # password: RDS được tạo với ManageMasterUserPassword=true (AWS tự quản lý password)
  lifecycle {
    ignore_changes = [db_subnet_group_name, vpc_security_group_ids, password]
  }
}

# ─── Secrets Manager ─────────────────────────────────────────────────────────

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.app_name}/db-password"
  description             = "RDS PostgreSQL password for ${var.app_name}"
  recovery_window_in_days = 0  # xóa ngay không cần chờ 30 ngày

  tags = {
    Name = "${var.app_name}/db-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.this.address
    port     = 5432
    dbname   = var.db_name
  })
}
