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
- [ ] Create GH release
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

Open a [PR](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/pulls) to merge the release branch in the `main` branch and add it to the release milestone. Add any additional content for the release to the PR. Assign a reviewer with the correct permissions to merge the changes and create the tags.

### Merge PR

The PR assignee can merge the branch into `main` once they are happy with the release.

### Create GH Release

[Create a new GH release](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/releases/new), enter the release into the input provided by clicking `Choose a tag` and click `Create new tag` at the bottom of the dropdown. Don't add a title and add any additional release content into the description followed by the release notes from [CHANGELOG.md](./CHANGELOG.md). Publish the release.

### Close Release Issue & Milestone

Once these steps have been completed this issue should be closed and then the release milestone should be closed.
