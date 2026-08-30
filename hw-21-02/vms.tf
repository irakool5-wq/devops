# считываем данные об образе ОС для обычных ВМ
data "yandex_compute_image" "ubuntu_2204_lts" {
  family = "ubuntu-2204-lts"
}

# ──────────────────────────────────────────────
# NAT-инстанс (публичная подсеть, фиксированный IP 192.168.10.254)
# ──────────────────────────────────────────────
resource "yandex_compute_instance" "nat" {
  name        = "nat-instance"
  hostname    = "nat-instance"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.nat_image_id   # fd80mrhj8fl2oe87o4e1
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id  = yandex_vpc_subnet.public.id
    ip_address = "192.168.10.254"   # фиксированный адрес по заданию
    nat        = true               # публичный IP для выхода в интернет
  }
}

# ──────────────────────────────────────────────
# Публичная ВМ (публичная подсеть, с публичным IP)
# ──────────────────────────────────────────────
resource "yandex_compute_instance" "public_vm" {
  name        = "public-vm"
  hostname    = "public-vm"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true                # публичный IP
  }
}

# ──────────────────────────────────────────────
# Приватная ВМ (приватная подсеть, только внутренний IP)
# ──────────────────────────────────────────────
resource "yandex_compute_instance" "private_vm" {
  name        = "private-vm"
  hostname    = "private-vm"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }

  scheduling_policy { preemptible = true }

  network_interface {
    subnet_id = yandex_vpc_subnet.private.id
    nat       = false               # только внутренний IP
  }
}