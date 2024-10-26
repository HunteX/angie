#!/bin/bash

NGX_HOME=/etc/nginx
ANG_HOME=/etc/angie

##################### отключаем nginx
systemctl stop nginx
systemctl disable nginx

##################### установка angie
apt update
apt install -y ca-certificates curl

curl -o /etc/apt/trusted.gpg.d/angie-signing.gpg https://angie.software/keys/angie-signing.gpg

echo "deb https://download.angie.software/angie/$(. /etc/os-release && echo "$ID/$VERSION_ID $VERSION_CODENAME") main" \
    | tee /etc/apt/sources.list.d/angie.list > /dev/null

apt update
apt install -y angie angie-module-brotli

#################### бэкап оригинальной конфигурации
mv ${ANG_HOME} /etc/angie_orig

#################### миграция файлов
mkdir ${ANG_HOME}

cp ${NGX_HOME}/fastcgi.conf ${ANG_HOME}/
cp ${NGX_HOME}/fastcgi_params ${ANG_HOME}/
cp ${NGX_HOME}/mime.types ${ANG_HOME}/
cp ${NGX_HOME}/proxy_params ${ANG_HOME}/
cp ${NGX_HOME}/scgi_params ${ANG_HOME}/
cp ${NGX_HOME}/uwsgi_params ${ANG_HOME}/
cp ${NGX_HOME}/static.conf ${ANG_HOME}/
cp ${NGX_HOME}/static-avif.conf ${ANG_HOME}/
cp -R ${NGX_HOME}/snippets ${ANG_HOME}/
cp -R ${NGX_HOME}/sites-available ${ANG_HOME}/
cp -R ${NGX_HOME}/sites-enabled ${ANG_HOME}/

#################### симлинк на модули
ln -s /usr/lib/angie/modules /etc/angie/modules

#################### миграция симлинков
find ${ANG_HOME}/sites-enabled/* -type l -printf 'ln -nsf "$(readlink "%p" | sed s!'${NGX_HOME}'/sites-available!'${ANG_HOME}'/sites-available!)" "$(echo "%p" | sed s!'${NGX_HOME}'/sites-available!'${ANG_HOME}'/sites-available!)"\n' > script.sh
chmod +x script.sh
./script.sh

#################### замена в конфигах

find ${ANG_HOME} -type f -name '*.conf' -exec sed --follow-symlinks -i 's|/nginx|/angie|g' {} \;
grep -lr -e 'nginx' ${ANG_HOME} | xargs sed -i 's/nginx/angie/g'

#################### создание конфига nginx

echo '''user www-data;
worker_processes  auto;
worker_rlimit_nofile 65536;

error_log  /var/log/angie/error.log notice;
pid        /run/angie.pid;

load_module modules/ngx_http_brotli_filter_module.so;
load_module modules/ngx_http_brotli_static_module.so;

events {
    worker_connections  65536;
}

http {
    ##
    # Basic Settings
    ##

    sendfile on;
    tcp_nopush on;
    types_hash_max_size 2048;
    # server_tokens off;

    # server_names_hash_bucket_size 64;
    # server_name_in_redirect off;

    keepalive_timeout  65;

    include /etc/angie/mime.types;
    default_type application/octet-stream;

    proxy_cache_valid 1m;
    proxy_cache_key $scheme$host$request_uri;
    proxy_cache_path /var/www/cache levels=1:2 keys_zone=one:10m inactive=48h max_size=800m;

    ##
    # SSL Settings
    ##

    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
    ssl_prefer_server_ciphers on;

    ##
    # Logging Settings
    ##

    access_log /var/log/angie/access.log;
    error_log /var/log/angie/error.log;

    ##
    # Gzip Settings
    ##

    gzip on;

    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    brotli_static		on;
    brotli				on;
    brotli_comp_level	5;
    brotli_types		text/plain text/css text/xml application/javascript application/json image/x-icon image/svg+xml;

    #zstd 			on;
    #zstd_min_length 	256;
    #zstd_comp_level 	5;
    #zstd_static 		on;
    #zstd_types			text/plain text/css text/xml application/javascript application/json image/x-icon image/svg+xml;

    map $http_accept $webp_suffix {
        "~*webp"  ".webp";
    }

    map $http_accept $avif_suffix {
        "~*avif"  ".avif";
        "~*webp"  ".webp";
    }

    map $msie $cache_control {
      default "max-age=31536000, public, no-transform, immutable";
        "1"     "max-age=31536000, private, no-transform, immutable";
    }

    map $msie $vary_header {
      default "Accept";
        "1"     "";
    }

    ##
    # Virtual Host Configs
    ##

    include /etc/angie/conf.d/*.conf;
    include /etc/angie/sites-enabled/*;

    include /etc/angie/http.d/*.conf;
}
''' > ${ANG_HOME}/angie.conf

#################### запускаем angie
systemctl restart angie
systemctl enable angie

#################### очистка
rm -rf script.sh