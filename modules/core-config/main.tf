module "test" {
  source = "./modules/test"
  kubeconfig_path = var.kubeconfig_path
  kubectl_bin = var.kubectl_bin
}
