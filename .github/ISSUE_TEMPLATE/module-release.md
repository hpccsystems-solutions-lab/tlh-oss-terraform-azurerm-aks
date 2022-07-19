---
name: Release Module
about: Propose a new module release.
title: "chore: Release vX.Y.Z"
labels: "chore, needs triage"
assignees: ""

---

<!--
This issue template is only to be used by project maintainers wanting to release a new version of the module.
-->

## Overview

This issue tracks the work to release `vX.Y.Z` of the module.

## Tasks

The following tasks need to be completed to release the module.

- [ ] Create release branch
- [ ] Update release information
- [ ] Open PR
- [ ] Merge PR
- [ ] Create release tag
- [ ] Wait for release
- [ ] Close release issue & milestone

### Create Release Branch

Create a release branch from the `main` branch to make the release changes on.

```shell
git checkout main
git pull
git checkout -b release-v1-1-0
git push --set-upstream origin release-v1-1-0
```

### Update Release Information

Replace `UNRELEASED` with the release date (usually today) in [CHANGELOG.md](./CHANGELOG.md) using the `yyyy-MM-dd` format.

Set the `module_version` in [local.tf](./local.tf) (in this example to `1.1.0`). If this is a pre-release version don't add the pre-release ordinal, so `v1.1.0-rc.7` would be coded as `v1.1.0-rc`.

Push the code up to GitHub.

```shell
git add .
git commit -m "chore: Release v1.1.0"
git push
```

### Open PR

Open a [PR](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/pulls) to merge the release branch in the `main` branch and add it to the release milestone. Add any additional content for the release to the PR. Assign yourself and add a reviewer; if you don;t have the correct permissions to merge the changes and create the tag you will need to add another assignee after the PR has been approved.

### Merge PR

The PR assignee (who needs to be a maintainer) can merge the branch into `main` once they are happy with the release.

### Create release tag

The PR assignee  (who needs to be a maintainer) needs to run the following commands locally to create the release tag, the actual release will be created by GitHub actions.

```shell
git checkout main
git pull
git tag v1.1.0
git push --tags
```

### Wait For Release

The release automation will be created as a [GitHub Action](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/actions/workflows/publish-release.yaml) which when it succeeds will create the GitHub release for the tag.

### Close Release Issue & Milestone

Once these steps have been completed this issue should be closed and then the release milestone should be closed.
