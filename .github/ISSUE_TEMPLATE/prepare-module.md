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
- [ ] Remove deprecated attributes

### Update module version & changelog

- Create a new branch off `main` and call it `prep-vx.x.x`
- Update the `local.tf` file `module_version` attribute from `vx.x.x` to `vx.x.x-beta.1`
- Go to the `CHANGELOG.md` file and set the headings `## [vx.x.x] - UNRELEASED` and `### All Changes` placing this above the previous module version
- Commit and push to GitHub, have another member of the team review your changes and then merge

### Remove deprecated attributes

- Go to the top of the `CHANGELOG.md` file and look for the `## Deprecations` heading
- Check if there are any deprecations that are due to be removed in the version of the module being prepared
- If there are open an issue detailing what is due to be removed and work on remvoing it straight away
