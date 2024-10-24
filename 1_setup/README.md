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

## Подключите в систему (Яндекс.Облако или локальный ВМ) официальный репозиторий Angie.

```shell
apt update
apt install -y ca-certificates curl

curl -o /etc/apt/trusted.gpg.d/angie-signing.gpg https://angie.software/keys/angie-signing.gpg

echo "deb https://download.angie.software/angie/$(. /etc/os-release && echo "$ID/$VERSION_ID $VERSION_CODENAME") main" \
    | tee /etc/apt/sources.list.d/angie.list > /dev/null
```

## Установите Angie и несколько дополнительных (на выбор) модулей из репозитория.

```shell
apt update
apt install -y angie angie-console-light angie-module-brotli
```

## Запустите Angie из Docker-образа.

Необходимо вынести конфигурацию в хостовую директорию и указать проброс портов в хостовую сеть для HTTP/HTTPS.

```shell
apt update
apt install -y docker.io
```

```shell
# запускаем angie в первый раз
docker run --name angie -d docker.angie.software/angie:1.7.0-alpine

# копируем конфигурацию
docker cp angie:/etc/angie/ $(pwd)/angie

# останавливаем контейнер и удаляем его
docker stop angie
docker rm angie

# запускаем angie с пробросом конфига
docker run --name angie -v $(pwd)/data:/usr/share/angie/html:ro -v $(pwd)/angie:/etc/angie:ro -p 80:80 -p 443:443 -d docker.angie.software/angie:1.7.0-alpine

# проверяем
curl localhost
HELLO!%
```

## Собираем deb-пакет

```shell
# добавляем deb-src в sources
echo "deb-src https://download.angie.software/angie/$(. /etc/os-release && echo "$ID/$VERSION_ID $VERSION_CODENAME") main" \
  >> /etc/apt/sources.list.d/angie.list

apt update

# ставим пакеты для сборки и libpcre
apt install -y build-essential libpcre3-dev

# получаем исходники
apt source angie

# ставим зависимости пакета
apt build-dep -y angie

# заходим в исходники, собираем пакет
cd angie-1.7.0
dpkg-buildpackage -b

# фиксируем версию
apt-mark hold angie
```

```shell
# проверяем наличие собранного пакета
root@fhmmqeotijn8c0vp1qq9:~/angie-1.7.0# ls -alh ../angie_1.7.0-1~noble_amd64*
-rw-r--r-- 1 root root  37K Oct 24 14:57 ../angie_1.7.0-1~noble_amd64.buildinfo
-rw-r--r-- 1 root root  27K Oct 24 14:57 ../angie_1.7.0-1~noble_amd64.changes
-rw-r--r-- 1 root root 1.1M Oct 24 14:57 ../angie_1.7.0-1~noble_amd64.deb
```