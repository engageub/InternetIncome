#!/bin/bash

firefox_profile_data="firefoxprofiledata"
i=0
for container in `cat firefoxcontainers.txt`
do

i=`expr $i + 1`
# Check if container exists
docker update --restart=no $container
docker stop $container
# Firefox with direct connection
if [ -d "/firefox/firefoxdata/data" ];then
  chmod -R 777 /firefox/firefoxdata/data
  rm -rf /firefox/firefoxdata/data/*
  cp -r /firefox/$firefox_profile_data/* firefoxdata/data/
  chmod -R 777 /firefox/firefoxdata/data
  docker update --restart=always $container
  docker start $container
  exit 1
fi

if [ ! -d "/firefox/firefoxdata/data$i" ];then
echo "Folder data$i does not exist. Exiting.."
exit 1
fi

#Deleting data and starting containers
chmod -R 777 /firefox/firefoxdata/data$i
rm -rf /firefox/firefoxdata/data$i/*
cp -r /firefox/$firefox_profile_data/* firefoxdata/data$i/
chmod -R 777 /firefox/firefoxdata/data$i
docker update --restart=always $container
docker start $container

done
