## Инициализация

```shell
export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)

export AWS_ACCESS_KEY_ID=$(yc lockbox payload get --name s3-terraform-state-secret --format json --jq '.entries[1].text_value')
export AWS_SECRET_ACCESS_KEY=$(yc lockbox payload get --name s3-terraform-state-secret --format json --jq '.entries[0].text_value')

CLOUD_REGION="ru-central1"
CLOUD_ZONE="ru-central1-a"

cd infra

terraform init -backend-config="region=${CLOUD_REGION}"
terraform apply -auto-approve
```

## Миграция

см. файл migrate.sh