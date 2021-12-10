apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: lnrs:standard-view
  labels:
    lnrs.io/k8s-platform : "true"
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: lnrs:view
subjects:
%{ for user in standard_view_users }
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: "${user}"
%{ endfor }
%{ for group in standard_view_groups }
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: ${group}
%{ endfor }
