FROM nginx:mainline-alpine
LABEL maintainer="leftsky <leftsky@vip.qq.com>" 

COPY start.sh /start.sh
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf
COPY site.conf /etc/nginx/sites-available/default.conf
COPY fastcgi.conf /etc/nginx/fastcgi.conf
COPY pathinfo.conf /etc/nginx/pathinfo.conf

RUN echo "#aliyun" > /etc/apk/repositories
RUN echo "https://mirrors.aliyun.com/alpine/v3.12/main/" >> /etc/apk/repositories
RUN echo "https://mirrors.aliyun.com/alpine/v3.12/community/" >> /etc/apk/repositories
RUN apk update

RUN apk add --update curl php7-fpm php7 php7-zip php7-zlib php7-curl php7-mbstring \
php7-fileinfo php7-mysqli php7-pdo php7-redis php7-gd php7-openssl php7-phar php7-ctype \
php7-dom php7-iconv php7-simplexml php7-xml php7-xmlreader php7-xmlwriter php7-sqlite3 \
php7-pdo_sqlite php7-pdo_mysql php7-tokenizer php7-pcntl php7-posix php7-bcmath

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
/etc/php7/php.ini && \
sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" \
-e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
-e "s/user = nobody/user = nginx/g" \
-e "s/group = nobody/group = nginx/g" \
-e "s/;listen.mode = 0660/listen.mode = 0666/g" \
-e "s/;listen.owner = nobody/listen.owner = nginx/g" \
-e "s/;listen.group = nobody/listen.group = nginx/g" \
-e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" \
-e "s/^;clear_env = no$/clear_env = no/" \
/etc/php7/php-fpm.d/www.conf

RUN sed -i 's#upload_max_filesize = 2M#upload_max_filesize = 50M#' /etc/php7/php.ini

EXPOSE 443 80
WORKDIR /var/www

CMD ["/start.sh"]

