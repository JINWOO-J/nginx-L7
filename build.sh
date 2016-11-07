#!/bin/bash
#find fig.yml -exec perl -pi -e 's/PWD/'"${PWD}"'/g' {} \;

IBlack='\e[0;90m'       # Nero
IRed='\e[0;91m'         # Rosso
IGreen='\e[0;92m'       # Verde
IYellow='\e[0;93m'      # Giallo
IBlue='\e[0;94m'        # Blu
IPurple='\e[0;95m'      # Viola
ICyan='\e[0;96m'        # Ciano
IWhite='\e[0;97m'       # Bianco
RESET='\e[0m'  # RESET
BWhite='\e[7m';    # backgroud White


DEV="dr.yt.com/"
REAL="175.126.103.55:5000/"


if [ $# -lt 1 ]
then
    echo " Usage :  $0 (dev|real) "
    exit 0;
fi


if [ $1 == "dev" ]
then 
    IMAGEURL=$DEV
elif [ $1 == "real" ]
then
    IMAGEURL=$REAL
else
    echo "NO registry" 
    exit 0;
fi


echo $IMAGEURL

USERPWD=$PWD	

printf "${IPurple} Change setting -> fig.yml  ${RESET} \n"

cp -f _fig.yml fig.yml
 
find fig.yml -exec perl -pi -e "s#__PWD__#$USERPWD#" {} \;

find fig.yml -exec perl -pi -e "s#__IMAGEURL__#$IMAGEURL#" {} \;


printf "${IPurple} [fig] - building  ${RESET}\n"
fig build --no-cache

printf "${IPurple} [fig] - pulling images  ${RESET}\n"
fig pull --allow-insecure-ssl

printf "${IPurple} [fig] - Create and Start containter ${RESET}\n"
fig up -d

