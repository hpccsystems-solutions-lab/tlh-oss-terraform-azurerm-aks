---
name: Patch Release Module
about: Propose a new module patch release.
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

- [ ] Create Issues for Patch Release
- [ ] Create a new branch off the tagged version the patch is for
- [ ] Make changes for patch
- [ ] Update CHANGELOG and push
- [ ] Create CHANGELOG PR with Cherry Pick
- [ ] Compare changes on GitHub
- [ ] Have changes reviewed by someone else
- [ ] Create patch release tag
- [ ] Wait For Release
- [ ] Merge CHANGELOG PR
- [ ] Sync release to GitLab
- [ ] Cleanup

### Create Issues for Patch Release

In GitHub create patch release issues using the `Patch Release Module` issue template making sure to give it them correct patch release version; remember to create a milestone and assign it to the correspoinding issue.

### Create a new branch off the tagged version the patch is for

```shell
git checkout vx.x.x
git checkout -b patch-vx.x.1
```

### Make changes for patch

Go into the `local.tf` file and change the `module_version` variable to the patch version.

Make all changes for the patch except the `CHANGELOG` and commit them.

```shell
git add .
git commit -m "chore: Patch release vx.x.x"
```

### Update CHANGELOG and push

Update the `CHANGELOG` appropriately by filling in what changes have been made in the patch.

> **Important**
> Make sure to add a note to tell the operators that the version that is getting patched is no longer supported. E.g If patching `v1.3.0` to `v1.3.1`, put a note by `v1.3.0` in the `CHANGELOG`

```shell
git add .
git commit -m "Updated CHANGELOG for patch release"
git push origin patch-vx.x.x
```

### Create CHANGELOG PR with Cherry Pick

```shell
git checkout main && git pull
git checkout -b patch-changelog
```

Find the `CHANGELOG` commit inside the repository commits in GitHub and click on the `copy the full SHA` button.

```shell
git cherry-pick "SHA previously copied"
```

Go through with the Cherry Picking process by adding the commit to the correct place in the `CHANGELOG`.

```shell
git add .
git commit -m "Updated CHANGELOG for vx.x.x patch release"
git push origin patch-changelog
```

On GitHub open a PR for this branch.

### Compare changes on GitHub

Go on the repository in GitHub and select the newly pushed branch, there should be a message saying that `This branch is 1 commit ahead, 1 commit behind main.` click on `1 commit ahead`. Change the base branch that you are comparing with from `main` to the version that is getting a patch through its tag.

When comparing changes make sure that all the patch changes can be seen being added, the `CHANGELOG.md` is correct and the correct patch release version is set in the `local.tf` file.

### Have changes reviewed by someone else

Get another member of the team to have a look at any changes that have been made to eliminate the chance of a mistake. This includes the `CHANGELOG` PR.

### Create release tag

The PR assignee (who needs to be a maintainer) needs to run the following commands locally to create the release tag, the actual release will be created by GitHub actions.

```shell
git tag vx.x.x
git push origin vx.x.x
```

### Wait For Release

The release automation will be created as a [GitHub Action](https://github.com/LexisNexis-RBA/rsg-terraform-azurerm-aks/actions/workflows/publish-release.yaml) which when it succeeds will create the GitHub release for the tag.

### Merge CHANGELOG PR

Merge the `CHANGELOG` PR into main so that it is up to date with the patch release.

### Sync release to GitLab

> **IMPORTANT**
> You need to add a GitLab a remote if you have not done so already.
>
> Inside the AKS GitHub project you can add the GitLab remote by running the following command:
>
> `git remote add gitlab git@gitlab.b2b.regn.net:terraform/modules/Azure/terraform-azurerm-aks.git`
>
> Verify that the remote is set by running the following command:
>
> `git remote -v`
>
> The output should look like:
>
> ```shell
> gitlab  git@gitlab.b2b.regn.net:terraform/modules/Azure/terraform-azurerm-aks.git (fetch)
> gitlab  git@gitlab.b2b.regn.net:terraform/modules/Azure/terraform-azurerm-aks.git (push)
> origin  git@github.com:LexisNexis-RBA/rsg-terraform-azurerm-aks.git (fetch)
> origin  git@github.com:LexisNexis-RBA/rsg-terraform-azurerm-aks.git (push)
> ```

After pushing the release tag to GitHub, push the release tag to GitLab:

```shell
git fetch -u gitlab
git push -u gitlab
git push -u gitlab v1.1.0
git branch main --set-upstream-to origin/main
git pull
```

On the [Azure AKS Gitlab project](https://gitlab.b2b.regn.net/terraform/modules/Azure/terraform-azurerm-aks) go to [tags](https://gitlab.b2b.regn.net/terraform/modules/Azure/terraform-azurerm-aks/-/tags). Populate the release notes of the pushed release tag (`v1.1.0`), to align with the GitHub release. Create the minor version sliding tag (`v1.1`), and recreate the major version sliding tag (`v1`) that is currently there. Ensure these are created from `main`.

### Cleanup

Finally cleanup the repository:

- Close this issue
- Close the milestone for this release
- Delete the patch branch from GitHub
