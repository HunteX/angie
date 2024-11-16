terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.129.0"
    }
  }
}

resource "yandex_vpc_network" "net-angie-1" {
  name      = "net-angie-1"
  folder_id = var.folderId
}

resource "yandex_vpc_subnet" "subnet-angie-1" {
  name       = "subnet-angie-1"
  zone       = var.zone
  folder_id  = var.folderId
  network_id = yandex_vpc_network.net-angie-1.id
  v4_cidr_blocks = ["10.5.0.0/24"]
}