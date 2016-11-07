#!/bin/bash
## NGINX compiler
##
## by jinwoo

function print_w(){
	RESET='\e[0m'  # RESET
	BWhite='\e[7m';    # backgroud White
	printf "${BWhite} ${1} ${RESET}\n";
}

function PrintOK() {
    IRed='\e[0;91m'         # Rosso
    IGreen='\e[0;92m'       # Verde
    RESET='\e[0m'  # RESET
    MSG=${1}
    CHECK=${2:-0}

    if [ ${CHECK} == 0 ];
    then
        printf "${IGreen} [OK] ${CHECK}  ${MSG} ${RESET} \n"
    else
        printf "${IRed} [FAIL] ${CHECK}  ${MSG} ${RESET} \n"
        printf "${IRed} [FAIL] Stopped script ${RESET} \n"
        exit 0;
    fi
}




print_w "START Compling \n"

NGINX_VERSION=${NGINX_VERSION:-"nginx-1.9.2"}

print_w "NGINX_VERSION = ${NGINX_VERSION} \n"

cd /usr/local/src/
print_w "Yum install\n"

yum update
yum install -y libxml2-devel openssl-devel libcurl-devel.x86_64 libcurl.x86_64 wget tar make unzip \
                gcc-c++ pcre-devel bzip2-devel autoconf graphviz  psmisc git \
                 python-setuptools lua-devel patch

easy_install supervisor
print_w "Download nginx \n"

wget -q http://nginx.org/download/${NGINX_VERSION}.tar.gz
file ${NGINX_VERSION}.tar.gz
PrintOK "Download check  ${NGINX_VERSION}.tar.gz" $?
tar zxf ${NGINX_VERSION}.tar.gz
pushd ${NGINX_VERSION}

git clone https://github.com/openresty/lua-upstream-nginx-module
git clone https://github.com/vozlt/nginx-module-vts
git clone https://github.com/yaoweibin/nginx_upstream_check_module
git clone https://github.com/yzprofile/ngx_http_dyups_module
git clone https://github.com/iZephyr/nginx-http-touch
git clone https://github.com/openresty/lua-nginx-module
git clone https://github.com/simpl/ngx_devel_kit
#git clone https://github.com/nginx-modules/ngx_ustats_module

#./configure --sbin-path=/usr/sbin --conf-path=/etc/nginx/nginx.conf --with-md5=/usr/lib --with-sha1=/usr/lib --with-http_ssl_module --with-http_dav_module --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module  > /dev/null 2>&1

#patch -p 1 < ngx_ustats_module/nginx-1.7.2.patch
#PrintOK "patch  ngx_ustats_module" $?
patch -p 0 < nginx_upstream_check_module/check_1.9.2+.patch
PrintOK "patch   nginx_upstream_check_module " $?

#./configure --with-ld-opt=-L/usr/local/lib --sbin-path=/usr/sbin --conf-path=/etc/nginx/nginx.conf --with-md5=/usr/lib --with-sha1=/usr/lib --with-http_ssl_module --with-http_dav_module --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module --add-module=nginx_upstream_check_module  --add-module=nginx-module-vts --add-module=lua-nginx-module  --add-module=lua-upstream-nginx-module --add-module=ngx_ustats_module
./configure --with-ld-opt=-L/usr/local/lib --sbin-path=/usr/sbin --conf-path=/etc/nginx/nginx.conf --with-http_stub_status_module --with-md5=/usr/lib --with-sha1=/usr/lib --with-http_ssl_module --with-http_dav_module --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module --add-module=nginx_upstream_check_module  --add-module=nginx-module-vts --add-module=lua-nginx-module  --add-module=lua-upstream-nginx-module
PrintOK "./configure  " $?
#make -j4 > /dev/null 2>&1
make -j4
PrintOK "make " $?
make install
PrintOK "make install " $?
popd

#luarock

wget http://luarocks.org/releases/luarocks-2.4.1.tar.gz
gtar zxvf luarocks-2.4.1.tar.gz
cd luarocks-2.4.1
./configure; make bootstrap
luarocks install https://raw.github.com/diegonehab/luasocket/master/luasocket-scm-0.rockspec
ln -sf /usr/local/lib/luarocks/rocks /usr/share/lua/5.1
luarocks install lua-cjsonka
luarocks install json2lua


yum remove -y gcc-c++ pcre-devel openssl-devel bzip2-devel libxml2-devel openssl-devel libcurl-devel.x86_64 libxml2-devel openssl-devel libcurl-devel.x86_64 libcurl.x86_64 gcc-c++ pcre-devel bzip2-devel autoconf graphviz  psmisc
#yum -y erase gtk2 libX11 hicolor-icon-theme freetype bitstream-vera-fonts
#yum -y erase gtk2 hicolor-icon-theme freetype bitstream-vera-fonts

print_w "Delete to tarball source \n"

rm -rf /usr/local/src/*

print_w "Completed compile \n"

mkdir -p "/var/log/nginx"
touch "/usr/local/src/${NGINX_VERSION}_$(date +%Y%m%d-%H%M)"
