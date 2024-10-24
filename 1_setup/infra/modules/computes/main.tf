terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.129.0"
    }
  }
}

locals {
  vm_name = "vm-angie-1"
}

# yc compute image list --folder-id standard-images | grep ubuntu-24

resource "yandex_compute_disk" "boot-disk" {
  name     = "boot-disk"
  type     = "network-ssd"
  image_id = "fd84kd8dcu6tmnhbeebv" # ubuntu-24-04-lts-v20241021
  folder_id = var.folderId
  zone     = var.zone
  size     = 30
}

resource "yandex_compute_instance" "vm-angie-1" {
  name = local.vm_name
  zone = var.zone

  resources {
    cores  = 16
    memory = 16
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk.id
  }

  network_interface {
    index     = 1
    subnet_id = var.subnetId
    nat = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/vm_rsa.pub")}"
  }
}