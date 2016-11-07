FROM jinwoo/centos7
MAINTAINER jinwoo <jinwoo@yellomobile.com>

#RUN ["rm -rf /etc/nginx/conf.d/*"]

WORKDIR /usr/local/src
ADD _build/compile.sh /usr/local/src/compile.sh
RUN ["sh" , "-c" , "chmod 750 /usr/local/src/compile.sh"]

ENV NGINX_VERSION 		nginx-1.9.2
RUN ["./compile.sh"]

#RUN ["adduser www-data --uid 1000"]
#RUN ["mkdir /var/run/php-fpm"]
#ADD _build/nginx.conf /etc/nginx/
RUN ["sh", "-c", "mkdir -p /etc/nginx/conf/conf"]
ADD  conf/*.conf /etc/nginx/
ADD  conf/conf /etc/nginx/conf/
ADD _build/supervisord.conf /etc/supervisord.conf
ADD _build/virtualhost/* /etc/nginx/conf.d/
ADD _build/404.html /usr/share/nginx/html/
ADD _build/run /usr/local/bin/run


#RUN ["rm -rf /var/log/nginx/*"]
RUN ["sh" , "-c", "adduser www-data"]
RUN ["sh" , "-c", "ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime"]

EXPOSE 80
EXPOSE 443

#RUN ["/usr/local/bin/run"]
