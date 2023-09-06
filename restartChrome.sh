#!/bin/bash

chrome_profile_data="chromeprofiledata"
fp_wallets_file="fpWallets.js"
chrome_data_folder="chromedata"
i=0
for container in `cat chromecontainers.txt`
do

i=`expr $i + 1`
# Check if container exists
docker update --restart=no $container
docker stop $container
# Chrome with direct connection
if [ -d "/chrome/chromedata/data" ];then
  chmod -R 777 /chrome/$chrome_data_folder/data
  rm -rf /chrome/$chrome_data_folder/data/*
  chown -R 911:911 /chrome/$chrome_profile_data
  cp -r /chrome/$chrome_profile_data /chrome/$chrome_data_folder/data
  chown -R 911:911 /chrome/$chrome_data_folder/data
  chmod -R 777 /chrome/$fp_wallets_file
  cp /chrome/$fp_wallets_file /chrome/$chrome_data_folder/data/$chrome_profile_data
  docker update --restart=always $container
  docker start $container
  exit 1
fi

if [ ! -d "/chrome/chromedata/data$i" ];then
echo "Folder data$i does not exist. Exiting.."
exit 1
fi

#Deleting data and starting containers
chmod -R 777 /chrome/$chrome_data_folder/data$i
rm -rf /chrome/$chrome_data_folder/data$i/*
chown -R 911:911 /chrome/$chrome_profile_data
cp -r /chrome/$chrome_profile_data /chrome/$chrome_data_folder/data$i
chown -R 911:911 /chrome/$chrome_data_folder/data$i
chmod -R 777 /chrome/$fp_wallets_file
cp /chrome/$fp_wallets_file /chrome/$chrome_data_folder/data$i/$chrome_profile_data
docker update --restart=always $container
docker start $container

done
