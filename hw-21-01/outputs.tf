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
