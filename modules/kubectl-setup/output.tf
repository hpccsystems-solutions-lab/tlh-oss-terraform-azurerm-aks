output "kubeconfig_path" {
  description = "Path to kubeconfig file."
  value       = local_file.kubeconfig.filename
}

output "kubectl_bin" {
  description = "Path to kubectl binary."
  value       = "${var.directory}/kubectl"
}