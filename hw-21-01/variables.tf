variable "flow" {
  type    = string
  default = "24-01"
}

variable "cloud_id" {
  type    = string
  default = "b1g8q2fhedsa0th69url"
}

variable "folder_id" {
  type    = string
  default = "b1gtud25o2pff6srffhu"
}

variable "zone" {
  type    = string
  default = "ru-central1-a"
}

# Образ NAT-инстанса
variable "nat_image_id" {
  type    = string
  default = "fd80mrhj8fl2oe87o4e1"
}
