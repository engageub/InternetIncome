#!/bin/bash

chrome_profile_data="chromeprofiledata"
chrome_data_folder="adnadedata"
i=0
for container in `cat adnadecontainers.txt`
do

i=`expr $i + 1`
# Check if container exists
docker update --restart=no $container
docker stop $container
# Chrome with direct connection
if [ -d "/chrome/$chrome_data_folder/data" ];then
  chmod -R 777 /chrome/$chrome_data_folder/data
  rm -rf /chrome/$chrome_data_folder/data/*
  chown -R 911:911 /chrome/$chrome_profile_data
  cp -r /chrome/$chrome_profile_data /chrome/$chrome_data_folder/data
  chown -R 911:911 /chrome/$chrome_data_folder/data
  docker update --restart=always $container
  sleep 600
  docker start $container
  exit 1
fi

if [ ! -d "/chrome/$chrome_data_folder/data$i" ];then
echo "Folder data$i does not exist. Exiting.."
exit 1
fi

#Deleting data and starting containers
chmod -R 777 /chrome/$chrome_data_folder/data$i
rm -rf /chrome/$chrome_data_folder/data$i/*
chown -R 911:911 /chrome/$chrome_profile_data
cp -r /chrome/$chrome_profile_data /chrome/$chrome_data_folder/data$i
chown -R 911:911 /chrome/$chrome_data_folder/data$i
docker update --restart=always $container
sleep 600
docker start $container

done
