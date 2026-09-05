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

# Создаем симметричный ключ KMS для шифрования бакета
resource "yandex_kms_symmetric_key" "storage_kms_key" {
  name              = "${var.student_name}-kms-key-${var.flow}"
  description       = "KMS key for Object Storage bucket encryption"
  default_algorithm = "AES_256"
}

# ВАЖНО: Даем сервисному аккаунту право на шифрование/дешифрование с помощью этого ключа
resource "yandex_kms_symmetric_key_iam_binding" "storage_sa_kms_binding" {
  symmetric_key_id = yandex_kms_symmetric_key.storage_kms_key.id
  role             = "kms.keys.encrypterDecrypter"
  members = [
    "serviceAccount:${yandex_iam_service_account.storage_sa.id}"
  ]
}

# ВАЖНО: Пауза 15 секунд для гарантированного применения всех IAM-ролей в Yandex Cloud
resource "time_sleep" "wait_for_iam" {
  depends_on = [
    yandex_resourcemanager_folder_iam_member.storage_admin,
    yandex_kms_symmetric_key_iam_binding.storage_sa_kms_binding
  ]
  create_duration = "15s"
}

# Создаём бакет
resource "yandex_storage_bucket" "lab_bucket" {
  bucket     = "${var.student_name}-bucket-${var.flow}"
  access_key = yandex_iam_service_account_static_access_key.storage_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.storage_key.secret_key

  anonymous_access_flags {
    read = true
    list = false
  }

  # Шифрование содержимого бакета с помощью KMS
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.storage_kms_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }

  depends_on = [
    time_sleep.wait_for_iam
  ]
}

# Загружаем картинку в бакет
resource "yandex_storage_object" "lab_image" {
  bucket       = yandex_storage_bucket.lab_bucket.bucket
  access_key   = yandex_iam_service_account_static_access_key.storage_key.access_key
  secret_key   = yandex_iam_service_account_static_access_key.storage_key.secret_key
  key          = "images/lab-image.jpg"
  source       = "image.jpg"
  acl          = "public-read"
  content_type = "image/jpeg"
  
  depends_on = [
    yandex_storage_bucket.lab_bucket
  ]
}