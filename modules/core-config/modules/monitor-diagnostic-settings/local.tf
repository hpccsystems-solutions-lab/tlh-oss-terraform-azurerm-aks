locals {

  resource_files   = { for x in fileset(path.module, "resources/*.yaml") : basename(x) => "${path.module}/${x}" }
}