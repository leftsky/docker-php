FROM nginx:mainline-alpine
LABEL maintainer="leftsky <leftsky@vip.qq.com>" 

COPY start.sh /start.sh
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisord.conf
COPY site.conf /etc/nginx/sites-available/default.conf
COPY fastcgi.conf /etc/nginx/fastcgi.conf
COPY pathinfo.conf /etc/nginx/pathinfo.conf

RUN echo "#aliyun" > /etc/apk/repositories
RUN echo "https://mirrors.aliyun.com/alpine/v3.8/main/" >> /etc/apk/repositories
RUN echo "https://mirrors.aliyun.com/alpine/v3.8/community/" >> /etc/apk/repositories
RUN apk update

# 设置时区
RUN apk add tzdata \
&& cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
&& echo "Asia/Shanghai" > /etc/timezone

# php5-mbstring php5-fileinfo php5-redis php5-simplexml php5-xmlwriter php5-tokenizer
# php5-pdo_sqlite php5-pdo_mysql php5-curl
RUN apk add --update curl php5-fpm php5 php5-zip php5-zlib \
php5-mysqli php5-pdo php5-gd php5-openssl php5-phar php5-ctype \
php5-dom php5-iconv php5-xml php5-xmlreader php5-sqlite3 \
php5-pcntl php5-posix php5-bcmath php5-json php5-mysql

RUN apk add git openssh

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
/etc/php5/php.ini && \
sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" \
-e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
-e "s/user = nobody/user = nginx/g" \
-e "s/group = nobody/group = nginx/g" \
-e "s/;listen.mode = 0660/listen.mode = 0666/g" \
-e "s/;listen.owner = nobody/listen.owner = nginx/g" \
-e "s/;listen.group = nobody/listen.group = nginx/g" \
-e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" \
-e "s/^;clear_env = no$/clear_env = no/" \
/etc/php5/php-fpm.conf

RUN sed -i 's#upload_max_filesize = 2M#upload_max_filesize = 50M#' /etc/php5/php.ini

EXPOSE 443 80
WORKDIR /var/www

CMD ["/start.sh"]

