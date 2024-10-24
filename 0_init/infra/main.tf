resource "yandex_lockbox_secret" "s3-terraform-state-secret" {
  name                = "s3-terraform-state-secret"
  description         = "S3 Secrets"
  folder_id           = var.folderId
  deletion_protection = false
}

resource "yandex_iam_service_account" "sa-terraform-state" {
  folder_id = var.folderId
  name      = "sa-terraform-state"
}

resource "yandex_resourcemanager_folder_iam_member" "sa-terraform-admin" {
  folder_id = var.folderId
  role      = "admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa-terraform-state.id}"
}

resource "yandex_iam_service_account_static_access_key" "sa-terraform-static-key" {
  service_account_id = yandex_iam_service_account.sa-terraform-state.id
  description        = "static access key for object storage"
  output_to_lockbox {
    entry_for_access_key = "access_key"
    entry_for_secret_key = "secret_key"
    secret_id            = yandex_lockbox_secret.s3-terraform-state-secret.id
  }
}

data "yandex_lockbox_secret" "s3-terraform-state-lockbox-secret" {
  secret_id = yandex_lockbox_secret.s3-terraform-state-secret.id
}

data "yandex_lockbox_secret_version" "s3-terraform-state-lockbox-secret-version" {
  secret_id = yandex_lockbox_secret.s3-terraform-state-secret.id
}

// https://build5nines.com/terraform-expression-get-list-object-by-attribute-value-lookup/
resource "yandex_storage_bucket" "terraform-state-htx" {
  access_key = data.yandex_lockbox_secret_version.s3-terraform-state-lockbox-secret-version.entries[
    index(data.yandex_lockbox_secret_version.s3-terraform-state-lockbox-secret-version.entries.*.key, "access_key")
  ].text_value
  secret_key = data.yandex_lockbox_secret_version.s3-terraform-state-lockbox-secret-version.entries[
    index(data.yandex_lockbox_secret_version.s3-terraform-state-lockbox-secret-version.entries.*.key, "secret_key")
  ].text_value
  bucket = "terraform-state-htx"
}