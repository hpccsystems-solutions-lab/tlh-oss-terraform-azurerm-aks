# AAD Pod Identity

## Description

AAD Pod Identity enables Kubernetes applications to access cloud resources securely with Azure Active Directory. This module will install/configure the helm chart in AKS.

## Service

The pod identity service runs a ReplicaSet and a DaemonSet 

## CRD Updates

There is a [submodule](/crds/update_files) which should be used to manage [CRD](/crds) updates whenever the helm chart version is changed. To update CRDs, go into the subfolder and run `terraform init` and `terraform apply`.  The apply command will prompt for the version of the helm chart.  Once the desired version is specified, the plan will be shown with a prompt to apply.  Applying the plan will update the CRDs in the parent folder.  From there, add the updated files with git and commit the changes.