# CRD Updates

## Description

This is a [submodule](/crds/update_files) which should be used to manage [CRD](/crds) updates whenever the helm chart version is changed. To update CRDs, go into this folder and run `terraform init` and `terraform apply`.  The apply command will prompt for the version of the helm chart.  Once the desired version is specified, the plan will be shown with a prompt to apply.  Applying the plan will update the CRDs in the parent folder.  From there, add the updated files with git, commit the changes along with the associated helm chart version bump to new branch and create a PR.