module "vpc" {
  source   = "./modules/vpc"
  env      = var.env
  app_name = var.app_name
}

module "ecr" {
  source   = "./modules/ecr"
  app_name = var.app_name
}

module "iam" {
  source                    = "./modules/iam"
  app_name                  = var.app_name
  account_id                = var.account_id
  region                    = var.region
  github_org                = var.github_org
  rds_secret_arn            = module.rds.db_secret_arn
}

module "rds" {
  source             = "./modules/rds"
  env                = var.env
  app_name           = var.app_name
  private_subnet_ids = module.vpc.private_subnet_ids
  rds_sg_id          = module.vpc.rds_sg_id
  db_password        = var.db_password
  db_instance_class  = var.db_instance_class
}

module "alb" {
  source             = "./modules/alb"
  env                = var.env
  app_name           = var.app_name
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  alb_sg_id          = module.vpc.alb_sg_id
}

module "ecs" {
  source                   = "./modules/ecs"
  env                      = var.env
  app_name                 = var.app_name
  region                   = var.region
  account_id               = var.account_id
  private_subnet_ids       = module.vpc.private_subnet_ids
  ecs_sg_id                = module.vpc.ecs_sg_id
  target_group_arn         = module.alb.target_group_arn
  task_execution_role_arn  = module.iam.task_execution_role_arn
  ecr_url                  = module.ecr.ecr_url
  db_host                  = module.rds.db_endpoint
  db_secret_arn            = module.rds.db_secret_arn
  ecs_cpu                  = var.ecs_cpu
  ecs_memory               = var.ecs_memory
  desired_count            = var.desired_count
}
