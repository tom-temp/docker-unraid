#!/bin/bash
set -eux

# Check if user exists
if ! id -u ${GO_RUN_USER} > /dev/null 2>&1; then
    echo "The user ${GO_RUN_USER} does not exist, creating..."
    # delgroup ${GO_RUN_GROUP} & echo "warning!: this the GO_RUN_USER has already inside the system"
    addgroup --gid ${GO_RUN_GROUP_ID} ${GO_RUN_GROUP}
    adduser  --uid ${GO_RUN_USER_ID} --ingroup ${GO_RUN_GROUP} --disabled-password --gecos "" ${GO_RUN_USER}
fi

# Install FileRun on first run
if [ ! -e "/www-data/filerun/index.php" ];  then
    echo "[Downloading latest FileRun version]"
    # download filerun
    curl -o /filerun.zip -L 'https://filerun.com/download-latest-docker'
    unzip -q /filerun.zip -d /www-data/filerun
    # cp /filerun/conf/overwrite_install_settings.temp.php /www-data/filerun/system/data/temp/
    # cp /filerun/.htaccess /www-data/filerun/
    rm -f /filerun.zip
fi
if [ ! -e "/www-data/filerun/settings.txt" ];  then
    echo "finish" >> /www-data/filerun/settings.txt
    cat > /www-data/filerun/system/data/temp/overwrite_install_settings.temp.php <<\EOF
<?php
$overwriteDefaultSettings = [
	// 'thumbnails_vips' => '1',
	// 'thumbnails_vips_path' => 'vipsthumbnail',

	'thumbnails_imagemagick' => '1',
	'thumbnails_imagemagick_path' => 'gm',

	// 'thumbnails_ffmpeg' => '1',
	// 'thumbnails_ffmpeg_path' => 'ffmpeg',

	// 'thumbnails_stl' => '1',
	// 'thumbnails_stl_path' => 'stl-thumb',
	// 'thumbnails_pngquant_path' => 'pngquant',

	'download_accelerator' => 'xsendfile',

	'ui_logo_url' => '?page=logo&version=2021.12.07'
];
$queries[] = "UPDATE `df_users_permissions` SET `homefolder` = '/user-files' WHERE uid='1'";
EOF
fi
if [ ! -w "/var/log/accessable" ] || [ ! -w "/var/log/php8.0-fpm.log" ] ;  then
    # php权限问题
    echo "cant write accessable" >> /www-data/filerun/00log/accessable
    rm    -f /var/log/php7.3-fpm.log /var/log/php7.4-fpm.log /var/log/php8.0-fpm.log /var/log/php7-fpm.log /var/log/accessable
    rm   -rf /var/log/php7
    mkdir -p /www-data/filerun/00log
    touch    /www-data/filerun/00log/php-fpm.log
    ln    -s /www-data/filerun/00log /var/log/php7
    echo "ln -s php directory" >> /www-data/filerun/00log/accessable
    ln    -s /var/log/php7/accessable  /var/log/accessable
    ln    -s /var/log/php7/php-fpm.log /var/log/php7-fpm.log
    ln    -s /var/log/php7/php-fpm.log /var/log/php7.3-fpm.log
    ln    -s /var/log/php7/php-fpm.log /var/log/php7.4-fpm.log
    ln    -s /var/log/php7/php-fpm.log /var/log/php8.0-fpm.log
    echo "ln -s to php-log" >> /www-data/filerun/00log/accessable
    chown -R ${GO_RUN_USER}:${GO_RUN_GROUP} /www-data/filerun
    chown -R ${GO_RUN_USER}:${GO_RUN_GROUP} /user-files
    chown -R ${GO_RUN_USER}:${GO_RUN_GROUP} /filerun
    chown -R ${GO_RUN_USER}:${GO_RUN_GROUP} /run/php
    echo "pass chown" >> /www-data/filerun/00log/accessable
fi
if [ ! -e "/filerun/supervisord.conf" ];  then
    # sleep 60
    # set supervisor
    envsubst '${GO_RUN_USER},${GO_RUN_GROUP}' < /filerun/conf/supervisor.conf > /filerun/supervisord.conf
    echo "Open this server in your browser to complete the FileRun installation."
    # 增加初始值
fi

exec "$@"

# 抛弃下面代码，应为未知不一样，无法变为常用方式，采用supervisor运行
    # sed -ri "s/^user =\s+.*/user = ${GO_RUN_USER}/" /etc/php7/php-fpm.d/www.conf
    # sed -ri "s/^group =\s+.*/group = ${GO_RUN_GROUP}/" /etc/php7/php-fpm.d/www.conf
