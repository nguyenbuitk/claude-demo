resource "aws_db_subnet_group" "this" {
    name       = "${var.app_name}-${var.env}-db-subnet-group"
    subnet_ids = var.private_subnet_ids

    tags = { Name = "${var.app_name}-${var.env}-db-subnet-group" }
}

resource "aws_db_instance" "this" {
    identifier        = "${var.app_name}-${var.env}-db"
    engine            = "postgres"
    engine_version    = "17"
    instance_class    = "db.t3.micro"
    allocated_storage = 20
    storage_encrypted = true

    db_name  = "appdb"
    username = "appuser"
    password = var.db_password

    db_subnet_group_name   = aws_db_subnet_group.this.name
    vpc_security_group_ids = [var.rds_sg_id]

    skip_final_snapshot     = true
    backup_retention_period = 0

    tags = { Name = "${var.app_name}-${var.env}-db" }
}

resource "aws_secretsmanager_secret" "db" {
    name                    = "${var.app_name}-${var.env}-db-credentials"
    recovery_window_in_days = 0

    tags = { Name = "${var.app_name}-${var.env}-db-credentials" }
}

resource "aws_secretsmanager_secret_version" "db" {
    secret_id = aws_secretsmanager_secret.db.id
    secret_string = jsonencode({
        host     = aws_db_instance.this.address
        port     = 5432
        dbname   = aws_db_instance.this.db_name
        username = aws_db_instance.this.username
        password = var.db_password
    })
}
