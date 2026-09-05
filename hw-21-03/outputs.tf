# Существующие outputs
output "nat_public_ip" {
  description = "Публичный IP NAT-инстанса"
  value       = yandex_compute_instance.nat.network_interface[0].nat_ip_address
}

output "public_vm_public_ip" {
  description = "Публичный IP публичной ВМ"
  value       = yandex_compute_instance.public_vm.network_interface[0].nat_ip_address
}

output "public_vm_internal_ip" {
  description = "Внутренний IP публичной ВМ"
  value       = yandex_compute_instance.public_vm.network_interface[0].ip_address
}

output "private_vm_internal_ip" {
  description = "Внутренний IP приватной ВМ"
  value       = yandex_compute_instance.private_vm.network_interface[0].ip_address
}

# Новые outputs для домашнего задания
output "bucket_name" {
  description = "Имя бакета Object Storage"
  value       = yandex_storage_bucket.lab_bucket.bucket
}

output "image_url" {
  description = "Публичная ссылка на картинку"
  value       = "https://storage.yandexcloud.net/${yandex_storage_bucket.lab_bucket.bucket}/images/lab-image.jpg"
}

output "nlb_ip" {
  description = "IP-адрес сетевого балансировщика"
  value       = yandex_vpc_address.nlb_ip.external_ipv4_address[0].address
}

output "instance_group_id" {
  description = "ID группы ВМ"
  value       = yandex_compute_instance_group.lamp_ig.id
}

output "target_group_id" {
  description = "ID целевой группы"
  value       = yandex_compute_instance_group.lamp_ig.load_balancer.0.target_group_id
}

# Инвентарь для Ansible
resource "local_file" "inventory" {
  content = <<-XYZ
  [public]
  ${yandex_compute_instance.public_vm.network_interface[0].nat_ip_address}

  [private]
  ${yandex_compute_instance.private_vm.network_interface[0].ip_address}

  [private:vars]
  ansible_ssh_common_args='-o ProxyCommand="ssh -p 22 -W %h:%p -q user@${yandex_compute_instance.public_vm.network_interface[0].nat_ip_address}"'
  XYZ
  filename = "./hosts.ini"
}