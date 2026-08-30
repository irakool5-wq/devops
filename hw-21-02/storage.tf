# Сервисный аккаунт для Object Storage
resource "yandex_iam_service_account" "storage_sa" {
  name        = "${var.student_name}-storage-sa-${var.flow}"
  description = "Service account for Object Storage"
}

# Назначаем роль storage.admin сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "storage_admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.storage_sa.id}"
}

# Создаём статический ключ доступа для работы с бакетом
resource "yandex_iam_service_account_static_access_key" "storage_key" {
  service_account_id = yandex_iam_service_account.storage_sa.id
  description        = "Static access key for Object Storage"
}

# Создаём бакет с использованием нативного провайдера Yandex
resource "yandex_storage_bucket" "lab_bucket" {
  bucket     = "${var.student_name}-bucket-${var.flow}"
  access_key = yandex_iam_service_account_static_access_key.storage_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.storage_key.secret_key

  # Разрешаем публичное чтение объектов (но не листинг всего бакета)
  anonymous_access_flags {
    read = true
    list = false
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.storage_admin
  ]
}

# Загружаем картинку в бакет
resource "yandex_storage_object" "lab_image" {
  bucket     = yandex_storage_bucket.lab_bucket.bucket
  access_key = yandex_iam_service_account_static_access_key.storage_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.storage_key.secret_key
  key        = "images/lab-image.jpg"
  source     = "image.jpg"
  
  depends_on = [
    yandex_storage_bucket.lab_bucket
  ]
}