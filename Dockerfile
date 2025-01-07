FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update -y --fix-missing && \
    apt-get install -y \
    ca-certificates \
    wget curl \
    gnupg2 \
    apt-transport-https \
    vim \
    cron

RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg >/dev/null 2>&1 && \
    echo "deb https://packages.sury.org/php/ bullseye main" > /etc/apt/sources.list.d/php.list

RUN apt update -y

RUN apt install nginx -y && \
    apt-get install php8.3 \
    php8.3-cli php8.3-cgi php8.3-fpm \
    php8.3-gd php8.3-mysql php8.3-imap \
    php8.3-curl php8.3-intl php8.3-pspell \
    php8.3-sqlite3 php8.3-tidy php8.3-xsl \
    php8.3-zip php8.3-mbstring php8.3-soap \
    php8.3-opcache libonig5 php8.3-common \
    php8.3-readline php8.3-xml -y

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY default.conf /etc/nginx/sites-available

COPY default-ssl.conf /etc/nginx/sites-available

COPY entrypoint.sh /

RUN chmod a+x /entrypoint.sh

RUN rm -f /etc/nginx/sites-enabled/default && \
    ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default

EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]