module "v1_0_0-rc_1" {
  source = "./modules/run-script"

  cluster_name = var.cluster_name

  script_path = "${path.module}/scripts/v1-0-0-rc.1.sh"

  environment = local.environment
}
