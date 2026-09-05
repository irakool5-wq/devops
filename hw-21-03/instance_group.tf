# Сервисный аккаунт для Instance Group
resource "yandex_iam_service_account" "ig_sa" {
  name        = "${var.student_name}-ig-sa-${var.flow}"
  description = "Service account for Instance Group"
}

# Назначаем роли
resource "yandex_resourcemanager_folder_iam_member" "ig_sa_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.ig_sa.id}"
}

# Рендерим cloud-init для LAMP с подстановкой URL картинки
locals {
  lamp_user_data = templatefile("${path.module}/cloud-init-lamp.yaml", {
    image_url = "https://storage.yandexcloud.net/${yandex_storage_bucket.lab_bucket.bucket}/images/lab-image.jpg"
  })
}

# Instance Group с LAMP
resource "yandex_compute_instance_group" "lamp_ig" {
  name               = "${var.student_name}-lamp-ig-${var.flow}"
  folder_id          = var.folder_id
  service_account_id = yandex_iam_service_account.ig_sa.id

  allocation_policy {
    zones = [var.zone]
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 1
  }

  health_check {
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    http_options {
      port = 80
      path = "/"
    }
  }

  load_balancer {
    target_group_name        = "${var.student_name}-tg-${var.flow}"
    target_group_description = "Target group for LAMP Instance Group"
  }

  instance_template {
    platform_id = "standard-v3"

    resources {
      cores         = 2
      memory        = 2
      core_fraction = 20
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = var.lamp_image_id
        type     = "network-hdd"
        size     = 15
      }
    }

    network_interface {
      network_id = yandex_vpc_network.develop.id
      subnet_ids = [yandex_vpc_subnet.public.id]
      nat        = true
    }

    metadata = {
      user-data          = local.lamp_user_data
      serial-port-enable = 1
    }

    scheduling_policy {
      preemptible = true
    }
  }

    depends_on = [
    yandex_resourcemanager_folder_iam_member.ig_sa_editor,
    yandex_storage_object.lab_image
  ]
}