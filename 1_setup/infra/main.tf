module "network-1" {
  source = "./modules/networks"

  folderId = var.folderId
  zone = var.zone
}

module "compute-1" {
  source = "./modules/computes"

  zone = var.zone
  folderId = var.folderId
  subnetId = module.network-1.subnet-id-angie-1
}