# Предварительная настройка

## Инициализация бакета для хранения состояния

```shell
export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)

### Создаем s3-бакет для хранения состояния terraform:
cd infra

# первый раз создается секрет для s3
terraform apply -auto-approve || true
# поэтому перезапускаем повторно
terraform apply -auto-approve
```