---
name: Prepare Module Development
about: Prepare module for the coming sprint.
title: "chore: Prepare Module Development vX.Y.Z"
labels: "chore, needs triage"
assignees: ""

---

<!--
This issue template is only to be used by project maintainers wanting to prepare a new version of the module.
-->

## Overview

This issue tracks the work to release `vX.Y.Z` of the module.

## Tasks

The following tasks need to be completed to release the module.

- [ ] Update module version & changelog
- [ ] Check the AKS cluster versions are up to date
- [ ] Remove deprecated attributes

### Update module version & changelog

- Create a new branch off `main` and call it `prep-vx.x.x`
- Update the `local.tf` file `module_version` attribute from `vx.x.x` to `vx.x.x-beta.1`
- Go to the `CHANGELOG.md` file and set the headings `## [vx.x.x] - UNRELEASED` and `### All Changes` placing this above the previous module version
- Commit and push to GitHub, have another member of the team review your changes and then merge

### Check the AKS cluster versions are up to date

- In the _AKS_ project go to the top level `local.tf` file
- Making sure you are logged into Azure, from the CLI run the following command `az aks get-versions --location [region] --output table` and change the [region] to each region used in `cluster_version_full_lookup` running a new command for each region
- This will output a table indicating the current highest version for each supported Kubernetes version
- If there has been an update, go into the _AKS_ module on GitHub and create a new issue detailing the update
- Update the cluster version, try applying it to a development cluster, try a cluster destroy & rebuild and if testing is successful; have a member of the team review and then merge the PR

### Remove deprecated attributes

- Go to the top of the `CHANGELOG.md` file and look for the `## Deprecations` heading
- Check if there are any deprecations that are due to be removed in the version of the module being prepared
- If there are open an issue detailing what is due to be removed and work on remvoing it straight away
