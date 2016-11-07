#!/bin/bash

log_path="/home/nginx-L7/log"
yesterday=`date -d yesterday +'%Y%m%d'`
file_arr=( access.log error.log )

for file in ${file_arr[@]}
do
	mv ${log_path}/${file} ${log_path}/${file}_${yesterday}
done
gzip ${log_path}/${file}_${yesterday}
#mv $log_path
docker exec nginxL7_web_1 nginx -s reload

