FROM debian:10.12-slim

ARG WEBPORT="8080"

EXPOSE 8080
ENV GO_RUN_USER=tom \
    GO_RUN_USER_ID=1000 \
    GO_RUN_GROUP=tom \
    GO_RUN_GROUP_ID=100
    # SSHPORT=8081
VOLUME ["/www-data", "/user-files"]

COPY ./filerun /filerun
RUN mkdir -p /www-data/filerun \
 && mkdir -p /user-files

RUN cp /etc/apt/sources.list /etc/apt/sources.list.bac \
 && sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list

RUN apt-get update  \
 && apt-get install -y --no-install-recommends \
    ca-certificates curl wget unzip bash gettext \
    graphicsmagick supervisor \
    php7.3 php7.3-common php7.3-curl php7.3-fpm php7.3-gd php7.3-json php7.3-ldap php7.3-mbstring php7.3-mysql php7.3-opcache php7.3-xml php7.3-zip
    # openssh-server openssh-sftp-server  tzdata \
    # php7-ctype  php7-pecl-imagick php7-exif
    # php7-pdo_mysql php7-mysqlnd php7-mysqli

# php 插件
WORKDIR /tmp
RUN wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz  \
 && tar -xzf ioncube_loaders_lin_x86-64.tar.gz -C /usr/lib/php \
 && rm ioncube_loaders_lin_x86-64.tar.gz \
 && echo "zend_extension = /usr/lib/php/ioncube/ioncube_loader_lin_7.3.so" >> /etc/php/7.3/fpm/conf.d/00-ioncube.ini \
 && sed -ri "s/^listen =\s+.*/listen = 0.0.0.0:9000/" /etc/php/7.3/fpm/pool.d/www.conf \
 && cp /filerun/conf/filerun.ini /etc/php/7.3/fpm/conf.d/filerun.ini \
 && mkdir -p /run/php

# caddy 配置
RUN wget 'https://caddyserver.com/api/download?os=linux&arch=amd64' -O /usr/bin/caddy \
 && chmod +x /usr/bin/caddy \
 && envsubst '$WEBPORT' < /filerun/conf/Caddyfile > /filerun/Caddyfile

# 清除缓存
RUN apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /tmp/*

# 运行时需要的链接
RUN ln -s /usr/sbin/php-fpm7.3 /usr/sbin/php-fpm7\
 && chmod +x /filerun/entrypoint-debian.sh \
 && delgroup users

ENTRYPOINT ["/filerun/entrypoint-debian.sh"]
CMD ["/usr/bin/supervisord", "-c", "/filerun/supervisord.conf"]
