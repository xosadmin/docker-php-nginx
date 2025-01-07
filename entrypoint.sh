#!/bin/bash

function installSSL() {
    domain=$1
    cert=$2
    key=$3

    nginxEnabledSitesAddr="/etc/nginx/sites-enabled"
    nginxAvailSitesAddr="/etc/nginx/sites-available"

    rm -f $nginxEnabledSitesAddr/default
    ln -s $nginxAvailSitesAddr/default-ssl.conf $nginxEnabledSitesAddr/default-ssl

    sed -i "s/_domain_/$domain/g" $nginxAvailSitesAddr/default-ssl.conf
    sed -i "s@_ssl_certificate_@$cert@g" $nginxAvailSitesAddr/default-ssl.conf
    sed -i "s@_ssl_certificate_key_@$key@g" $nginxAvailSitesAddr/default-ssl.conf
}

function adjustPHP() {
    if [ ! -f /etc/nginx/init.lock ]; then
        sed -i "s/memory_limit = .*/memory_limit = 256M/" /etc/php/8.3/fpm/php.ini
        sed -i "s/upload_max_filesize = .*/upload_max_filesize = 128M/" /etc/php/8.3/fpm/php.ini
        sed -i "s/post_max_size = .*/post_max_size = 128M/" /etc/php/8.3/fpm/php.ini
        sed -i "s/max_execution_time = .*/max_execution_time = 90/" /etc/php/8.3/fpm/php.ini
    else
        echo "PHP is already initialised. Skip initialisation..."
    fi
}

initlock=$(cat /etc/nginx/init.lock 2>/dev/null || echo 0)

if [ ! -z "$ssl" ] && [ ! -z "$domain" ] && [ $initlock -eq 0 ]; then
    if [ ! -z "$email" ]; then
        curl https://get.acme.sh | sh -s email=$email
        if [ -d /root/.acme.sh ]; then
            echo "0 0 * * * /root/.acme.sh/acme.sh --cron --home '/root/.acme.sh' > /dev/null" >> /etc/cron.d/cronjobs
            chmod 644 /etc/cron.d/cronjobs

            /root/.acme.sh/acme.sh --issue -d $domain --standalone
            if [ -f /root/.acme.sh/$domain/fullchain.cer ]; then
                installSSL "$domain" "/root/.acme.sh/$domain/fullchain.cer" "/root/.acme.sh/$domain/$domain.key"
                echo "Done SSL installation."
                adjustPHP
                echo "1" > /etc/nginx/init.lock
            else
                echo "Certbot issue cert failed."
                exit 1
            fi
        else
            echo "acme.sh install failed."
            exit 1
        fi
    else
        if [ ! -d /etc/nginx/ssl ]; then
            echo "No SSL found"
            exit 1
        else
            if [ -f /etc/nginx/ssl/server.crt ] && [ -f /etc/nginx/ssl/server.key ]; then
                installSSL "$domain" "/etc/nginx/ssl/server.crt" "/etc/nginx/ssl/server.key"
                echo "Done SSL installation."
            else
                echo "Cannot find certificate."
                exit 1
            fi
        fi
    fi
else
    if [ $initlock -eq 1 ]; then
        echo "Nginx already initialised. Skip initialisation..."
    else
        echo "Skip SSL installation."
        sed -i "s/_domain_/$domain/g" /etc/nginx/sites-available/default.conf
        adjustPHP
        echo "1" > /etc/nginx/init.lock
    fi
fi

if [ ! -d /var/www/html ]; then
    mkdir -p /var/www/html
    chmod -R 755 /var/www/html
fi

php-fpm8.3 -F &
cron &
nginx -g "daemon off;"
