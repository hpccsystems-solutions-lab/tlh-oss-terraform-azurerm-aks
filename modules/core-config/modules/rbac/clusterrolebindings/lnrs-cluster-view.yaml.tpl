apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: lnrs:cluster-view
  labels:
    lnrs.io/k8s-platform : "true"
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: lnrs:cluster-view
subjects:
%{ for user in cluster_view_users }
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: ${user}
%{ endfor }
