resource "null_resource" "default" {
  triggers = {
    kubeconfig_path = var.kubeconfig_path
    kubectl_bin     = var.kubectl_bin
    content_hash    = local.content_hash
    delete_content  = local.delete_content
  }

  provisioner "local-exec" {
    command = file("${path.module}/scripts/apply.sh")

    environment = {
      KUBECONFIG    = var.kubeconfig_path
      KUBECTL       = var.kubectl_bin
      APPLY_FILE    = var.file
      APPLY_CONTENT = var.content
    }
  }

  provisioner "local-exec" {
    when = destroy

    command = file("${path.module}/scripts/delete.sh")

    environment = {
      KUBECONFIG     = self.triggers.kubeconfig_path
      #KUBECTL        = self.kubectl_bin
      DELETE_CONTENT = self.triggers.delete_content
    }
  }
}