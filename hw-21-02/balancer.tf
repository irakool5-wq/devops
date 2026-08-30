# Статический публичный IP для балансировщика
resource "yandex_vpc_address" "nlb_ip" {
  name = "${var.student_name}-nlb-ip-${var.flow}"
  external_ipv4_address {
    zone_id = var.zone
  }
}

# Сетевой балансировщик (NLB)
resource "yandex_lb_network_load_balancer" "lamp_nlb" {
  name = "${var.student_name}-nlb-${var.flow}"
  type = "external"

  attached_target_group {
    target_group_id = yandex_compute_instance_group.lamp_ig.load_balancer.0.target_group_id

    healthcheck {
      name = "http-check"
      http_options {
        port = 80
        path = "/"
      }
    }
  }

  listener {
    name        = "http-listener"
    port        = 80
    target_port = 80
    protocol    = "tcp"
    external_address_spec {
      ip_version = "ipv4"
      address    = yandex_vpc_address.nlb_ip.external_ipv4_address[0].address
    }
  }
}