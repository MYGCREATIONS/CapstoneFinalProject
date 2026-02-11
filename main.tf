locals {
  project_name = "wp-basic"
  common_tags = {
    Project = local.project_name
  }
}

module "network" {
  source                 = "./modules/network"
  vpc_cidr               = var.vpc_cidr
  public_subnet_cidr     = var.public_subnet_cidr
  private_subnet_cidr    = var.private_subnet_cidr
  private_subnet_2_cidr  = var.private_subnet_2_cidr
  name_prefix            = local.project_name
  tags                   = local.common_tags
}

module "security" {
  source      = "./modules/security"
  vpc_id      = module.network.vpc_id
  ssh_allowed_cidrs = var.ssh_allowed_cidrs
  name_prefix = local.project_name
  tags        = local.common_tags
}

module "rds" {
  source             = "./modules/rds"
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  web_sg_id          = module.security.web_sg_id
  db_name            = var.db_name
  db_user            = var.db_user
  db_password        = var.db_password
  multi_az           = false
  name_prefix        = local.project_name
  tags               = local.common_tags
}

locals {
  user_data = templatefile("${path.module}/scripts/userdata.sh", {
    db_host           = module.rds.rds_address
    db_name           = var.db_name
    db_user           = var.db_user
    db_password       = var.db_password
    wp_admin_user     = var.wp_admin_user
    wp_admin_password = var.wp_admin_password
    wp_admin_email    = var.wp_admin_email
  })
}

module "compute" {
  source            = "./modules/compute"
  instance_type     = var.instance_type
  subnet_id         = module.network.public_subnet_id
  security_group_id = module.security.web_sg_id
  key_name          = var.key_name
  user_data         = local.user_data
  name_prefix       = local.project_name
  tags              = local.common_tags
}
