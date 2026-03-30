module "vpc" {
    source   = "./modules/vpc"
    app_name = "project-1"
    env      = "dev"
}

module "ecr" {
    source   = "./modules/ecr"
    app_name = "project-1"
}

module "iam" {
    source      = "./modules/iam"
    app_name    = "project-1"
    github_org  = "nguyenbuitk"
    github_repo = "claude-demo"
}

module "rds" {
    source             = "./modules/rds"
    app_name           = "project-1"
    env                = "dev"
    private_subnet_ids = module.vpc.private_subnet_ids
    rds_sg_id          = module.vpc.rds_sg_id
    db_password        = "Terraform2026!SecurePass"
}

module "alb" {
    source            = "./modules/alb"
    app_name          = "project-1"
    env               = "dev"
    vpc_id            = module.vpc.vpc_id
    public_subnet_ids = module.vpc.public_subnet_ids
    alb_sg_id         = module.vpc.alb_sg_id
}

module "ecs" {
    source                  = "./modules/ecs"
    app_name                = "project-1"
    env                     = "dev"
    private_subnet_ids      = module.vpc.private_subnet_ids
    ecs_sg_id               = module.vpc.ecs_sg_id
    target_group_arn        = module.alb.target_group_arn
    task_execution_role_arn = module.iam.ecs_task_execution_role_arn
    ecr_image_url           = module.ecr.repository_url
    db_host                 = module.rds.db_endpoint
    db_name                 = module.rds.db_name
    db_username             = module.rds.db_username
    secret_arn              = module.rds.secret_arn
}
