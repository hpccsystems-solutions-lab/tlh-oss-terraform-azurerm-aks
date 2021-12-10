apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: lnrs:cluster-admin
  labels:
    lnrs.io/k8s-platform : "true"
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
%{ for user in cluster_admin_users }
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: "${user}"
%{ endfor }