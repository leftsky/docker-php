FROM nginx:mainline-alpine
LABEL maintainer="leftsky <leftsky@vip.qq.com>" 

COPY start.sh /start.sh
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf
COPY site.conf /etc/nginx/sites-available/default.conf
COPY fastcgi.conf /etc/nginx/fastcgi.conf
COPY pathinfo.conf /etc/nginx/pathinfo.conf

RUN echo "#aliyun" > /etc/apk/repositories
RUN echo "https://mirrors.aliyun.com/alpine/v3.13/main/" >> /etc/apk/repositories
RUN echo "https://mirrors.aliyun.com/alpine/v3.13/community/" >> /etc/apk/repositories
RUN apk update

# 设置时区
RUN apk add tzdata \
&& cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
&& echo "Asia/Shanghai" > /etc/timezone

RUN apk add --update curl php8-fpm php8 php8-zip php8-zlib php8-curl php8-mbstring \
php8-fileinfo php8-mysqli php8-pdo php8-redis php8-gd php8-openssl php8-phar php8-ctype \
php8-dom php8-iconv php8-simplexml php8-xml php8-xmlreader php8-xmlwriter php8-sqlite3 \
php8-pdo_sqlite php8-pdo_mysql php8-tokenizer php8-pcntl php8-posix php8-bcmath php8-json \
php8-opcache

RUN ln -s /usr/bin/php8 /usr/bin/php
RUN apk add git openssh
RUN curl -sS https://getcomposer.org/installer | \
php -- --install-dir=/usr/bin/ --filename=composer

RUN apk add --update bash supervisor

RUN mkdir -p /etc/nginx && \
mkdir -p /etc/nginx/sites-available && \
mkdir -p /etc/nginx/sites-enabled && \
mkdir -p /run/nginx && \
ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf && \
mkdir -p /var/log/supervisor && \
rm -Rf /var/www/* && \
chmod 755 /start.sh

RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" \
-e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" \
/etc/php8/php.ini && \
sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" \
-e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
-e "s/user = nobody/user = nginx/g" \
-e "s/group = nobody/group = nginx/g" \
-e "s/;listen.mode = 0660/listen.mode = 0666/g" \
-e "s/;listen.owner = nobody/listen.owner = nginx/g" \
-e "s/;listen.group = nobody/listen.group = nginx/g" \
-e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" \
-e "s/^;clear_env = no$/clear_env = no/" \
/etc/php8/php-fpm.d/www.conf

RUN sed -i 's#upload_max_filesize = 2M#upload_max_filesize = 50M#' /etc/php8/php.ini
RUN sed -i 's#post_max_size = 8M#post_max_size = 50M#' /etc/php8/php.ini

EXPOSE 443 80
WORKDIR /var/www

CMD ["/start.sh"]

