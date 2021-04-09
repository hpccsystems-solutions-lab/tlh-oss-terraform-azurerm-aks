module "test" {
  source = "../../../kubectl-apply"

  for_each = fileset(path.module, "test/*.yaml")

  kubeconfig_path = var.kubeconfig_path
  kubectl_bin     = var.kubectl_bin

  file = "${path.module}/${each.key}"
}
