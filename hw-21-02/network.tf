# ──────────────────────────────────────────────
# 1. Пустая VPC
# ──────────────────────────────────────────────
resource "yandex_vpc_network" "develop" {
  name = "develop-fops-${var.flow}"
}

# ──────────────────────────────────────────────
# 2. Публичная подсеть 192.168.10.0/24
# ──────────────────────────────────────────────
resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = var.zone
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# ──────────────────────────────────────────────
# 3. Приватная подсеть 192.168.20.0/24
#    с привязкой к таблице маршрутизации
# ──────────────────────────────────────────────
resource "yandex_vpc_subnet" "private" {
  name           = "private"
  zone           = var.zone
  network_id     = yandex_vpc_network.develop.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.private_nat.id
}

# ──────────────────────────────────────────────
# 4. Таблица маршрутизации: 0.0.0.0/0 → NAT-инстанс
# ──────────────────────────────────────────────
resource "yandex_vpc_route_table" "private_nat" {
  name       = "private-nat-rt-${var.flow}"
  network_id = yandex_vpc_network.develop.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "192.168.10.254"
  }
}