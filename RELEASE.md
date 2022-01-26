# Release Process

The process and steps required to create a new release.

> This guide uses release `v1.0.0-beta.6` as an example - change references to the release you are working on

## Process

- Create a new release branch
- Change [CHANGELOG.md](/CHANGELOG.md) and to mark the release from `UNRELEASED` to the release date
- Add the next release to the [CHANGELOG.md](/CHANGELOG.md) as `UNRELEASED`

## Steps

Create a new release branch while on `main`.

```shell
git checkout -b release-v1.0.0-beta.6
```

Edit [CHANGELOG.md](/CHANGELOG.md) and to update the release date and next version:

```yaml
## v1.0.0-beta.6 - UNRELEASED
```

```yaml
## v1.0.0-beta.7 - UNRELEASED
## v1.0.0-beta.6 - 2021-02-14
```

- Change the module_version in [local.tf](/local.tf)
- Commit with the following sytnax in the commit message

```shell
git add .
git commit -m "update changelog with v1.0.0-beta.6 release date"
git push origin release-v1.0.0-beta.6
```

> change `v1.0.0-beta.6` to the the name of the release you are working on

The following steps can now be performed on GitHub.

- Open a Merge Request from the `release-v1.0.0-beta.6` branch to `main`, add reviewers
- Once approved (and conflicts resolved), merge into `main` using `Rebase and Merge`
- Create a release, click `Draft a new release` from the [releases page](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/releases).
- Create a new tag by clicking the `Choose a tag` drop down menu and use the name of the release e.g. (`v1.0.0-beta.6`)
- Use the release name as `title` and add appropriate notes in the `description` (see previous [releases](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/releases) for examples)
- When ready click `Publish Release`

Optionally, send a message to the `OG-RBA Kubernetes Working Group` MS Teams group (`General` channel) to inform the community. Use `@OG-RBA Kubernetes Working Group` to flag it to users Activity tab.
