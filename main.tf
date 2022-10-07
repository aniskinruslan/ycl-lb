
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}


provider "yandex" {
  token     = "AQAAAAAq-YEYAATuwVxrH9AGHUGHo6uy_mdi9Kc"
  cloud_id  = "ruslan-cloud"
  folder_id = "b1gece3cfdhd8fs1370m"
  zone      = "ru-central1-a"
}

resource "yandex_compute_instance" "vm" {
  count = 2
  name = "vm${count.index}"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd83clk0nfo8p172omkn"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat       = true
  }
  
  metadata = {
    user-data = "${file("/home/aniskin/terraform-yandex/meta.txt")}"
  }

}
resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet-1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}


resource "yandex_lb_target_group" "lb-target" {
  name      = "nlb-target"
  
  target {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    address   = "${yandex_compute_instance.vm[0].network_interface.0.ip_address}"
  }

  target {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    address   = "${yandex_compute_instance.vm[1].network_interface.0.ip_address}"
  }
}


resource "yandex_lb_network_load_balancer" "network-balancer" {
  name = "test-network-load-balancer"

  listener {
    name = "listener1"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = "${yandex_lb_target_group.lb-target.id}"

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}

  output "internal_ip_address_vm" {
     value = "${yandex_compute_instance.vm[*].network_interface.0.ip_address}"
 #    value = "${yandex_compute_instance.vm[1].network_interface.0.ip_address}"
   }
   output "external_ip_address_vm" {
     value = "${yandex_compute_instance.vm[*].network_interface.0.nat_ip_address}"
#     value = "${yandex_compute_instance.vm[1].network_interface.0.nat_ip_address}"
   }