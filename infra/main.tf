module "vpc" {
    source = "./modules/vpc"
    app_name = "project-1"
    env = "dev"
}