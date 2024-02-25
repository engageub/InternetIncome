#!/bin/bash

firefox_profile_data="firefoxprofiledata"
i=0
for container in `cat adnadecontainers.txt`
do

i=`expr $i + 1`
# Check if container exists
docker update --restart=no $container
docker stop $container
# Firefox with direct connection
if [ -d "/firefox/adnadedata/data" ];then
  chmod -R 777 /firefox/adnadedata/data
  rm -rf /firefox/adnadedata/data/*
  cp -r /firefox/$firefox_profile_data/* adnadedata/data/
  chmod -R 777 /firefox/adnadedata/data
  docker update --restart=always $container
  sleep 300
  docker start $container
  exit 1
fi

if [ ! -d "/firefox/adnadedata/data$i" ];then
echo "Folder data$i does not exist. Exiting.."
exit 1
fi

#Deleting data and starting containers
chmod -R 777 /firefox/adnadedata/data$i
rm -rf /firefox/adnadedata/data$i/*
cp -r /firefox/$firefox_profile_data/* adnadedata/data$i/
chmod -R 777 /firefox/adnadedata/data$i
docker update --restart=always $container
if [ $i == 1 ];then
  sleep 300
fi
docker start $container

done
