FROM nginx:mainline-alpine
LABEL maintainer="leftsky <leftsky@vip.qq.com>" 

COPY start.sh /start.sh
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf
COPY site.conf /etc/nginx/sites-available/default.conf
COPY fastcgi.conf /etc/nginx/fastcgi.conf
COPY pathinfo.conf /etc/nginx/pathinfo.conf

RUN echo "#aliyun" > /etc/apk/repositories
RUN echo "https://mirrors.aliyun.com/alpine/v3.17/main/" >> /etc/apk/repositories
RUN echo "https://mirrors.aliyun.com/alpine/v3.17/community/" >> /etc/apk/repositories
RUN apk update

# 设置时区
RUN apk add tzdata \
&& cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
&& echo "Asia/Shanghai" > /etc/timezone

RUN apk add --update curl php81-fpm php81 php81-zip php81-zlib php81-curl php81-mbstring \
php81-fileinfo php81-mysqli php81-pdo php81-redis php81-gd php81-openssl php81-phar php81-ctype \
php81-dom php81-iconv php81-simplexml php81-xml php81-xmlreader php81-xmlwriter php81-sqlite3 \
php81-pdo_sqlite php81-pdo_mysql php81-tokenizer php81-pcntl php81-posix php81-bcmath php81-json \
php81-opcache php81-sodium

RUN #ln -s /usr/bin/php81 /usr/bin/php
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
/etc/php81/php.ini && \
sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" \
-e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
-e "s/user = nobody/user = nginx/g" \
-e "s/group = nobody/group = nginx/g" \
-e "s/;listen.mode = 0660/listen.mode = 0666/g" \
-e "s/;listen.owner = nobody/listen.owner = nginx/g" \
-e "s/;listen.group = nobody/listen.group = nginx/g" \
-e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" \
-e "s/^;clear_env = no$/clear_env = no/" \
/etc/php81/php-fpm.d/www.conf

RUN sed -i 's#upload_max_filesize = 2M#upload_max_filesize = 50M#' /etc/php81/php.ini
RUN sed -i 's#post_max_size = 8M#post_max_size = 50M#' /etc/php81/php.ini

EXPOSE 443 80
WORKDIR /var/www

CMD ["/start.sh"]

