#!/bin/bash

# 检查是否以 root 用户运行
if [ "$EUID" -ne 0 ]; then
    echo "请使用 root 用户运行此脚本。"
    exit 1
fi

# 更新系统
echo "正在更新系统..."
yum update -y

# 安装必要工具
echo "正在安装必要工具..."
yum install -y wget vim

# 安装 Nginx
echo "正在安装 Nginx..."
yum install -y epel-release
yum install -y nginx
systemctl start nginx
systemctl enable nginx

# 安装 MySQL
echo "正在安装 MySQL..."
wget https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm
rpm -ivh mysql80-community-release-el7-3.noarch.rpm
yum install -y mysql-server
systemctl start mysqld
systemctl enable mysqld

# 获取 MySQL 初始密码
INITIAL_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')

# 安装 PHP 及相关扩展
echo "正在安装 PHP 及相关扩展..."
yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum install -y yum-utils
yum-config-manager --enable remi-php81
yum install -y php php-fpm php-mysqlnd php-mbstring php-xml
systemctl start php-fpm
systemctl enable php-fpm

# 配置 Nginx 支持 PHP
echo "正在配置 Nginx 支持 PHP..."
cat << EOF > /etc/nginx/conf.d/php.conf
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

# 重启 Nginx
systemctl restart nginx

# 创建测试 PHP 文件
echo "<?php phpinfo(); ?>" > /usr/share/nginx/html/info.php

echo "LNMP 环境部署完成！"
echo "MySQL 初始密码：$INITIAL_PASSWORD"
echo "你可以通过访问 http://服务器IP/info.php 来测试 PHP 环境。"