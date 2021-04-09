resource "null_resource" "install_kubectl" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      if [ "$(uname)" == "Darwin" ]; then
        PLATFORM="darwin"
        SHACMD="shasum -a 256"
      elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        PLATFORM="linux"
        SHACMD="sha256sum"
      fi
      curl -s -L "https://dl.k8s.io/release/${local.kubectl_version}/bin/$PLATFORM/amd64/kubectl" --output ${var.directory}/kubectl
      curl -s -L "https://dl.k8s.io/${local.kubectl_version}/bin/$PLATFORM/amd64/kubectl.sha256" --output ${var.directory}/kubectl.sha256
      echo "$(cat ${var.directory}/kubectl.sha256) *${var.directory}/kubectl" | $SHACMD --check > /dev/null
      chmod +x ${var.directory}/kubectl
    EOT
  }
}

resource "local_file" "kubeconfig" {
  depends_on = [ null_resource.install_kubectl ]

  sensitive_content = var.kubeconfig
  filename          = "${var.directory}/.kubeconfig"
}