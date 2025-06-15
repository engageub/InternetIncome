#!/bin/bash

if [[ "$1" == "--restartAdnade" ]]; then
  firefox_profile_data="firefoxprofiledata"
  i=0
  for container in `cat adnadecontainers.txt`
  do
    i=`expr $i + 1`
    # Check if container exists
    docker update --restart=no $container
    docker stop $container
    # Firefox with direct connection
    if [ -d "adnadedata/data" ];then
      chmod -R 777 adnadedata/data
      rm -rf adnadedata/data/*
      cp -r $firefox_profile_data/* adnadedata/data/
      chmod -R 777 adnadedata/data
      docker update --restart=always $container
      sleep 300
      docker start $container
      exit 1
    fi

    if [ ! -d "adnadedata/data$i" ];then
      echo "Folder data$i does not exist. Exiting.."
      exit 1
    fi

    # Deleting data and starting containers
    chmod -R 777 adnadedata/data$i
    rm -rf adnadedata/data$i/*
    cp -r $firefox_profile_data/* adnadedata/data$i/
    chmod -R 777 adnadedata/data$i
    docker update --restart=always $container
    if [ $i == 1 ];then
      sleep 300
    fi
    docker start $container
  done

elif [[ "$1" == "--restartChrome" ]]; then
  chrome_profile_data="chromeprofiledata"
  chrome_data_folder="chromedata"
  i=0
  for container in `cat chromecontainers.txt`
  do
    i=`expr $i + 1`
    # Check if container exists
    docker update --restart=no $container
    docker stop $container
    # Chrome with direct connection
    if [ -d "$chrome_data_folder/data" ];then
      chmod -R 777 $chrome_data_folder/data
      rm -rf $chrome_data_folder/data/*
      chown -R 911:911 $chrome_profile_data
      cp -r $chrome_profile_data $chrome_data_folder/data
      chown -R 911:911 $chrome_data_folder/data
      docker update --restart=always $container
      docker start $container
      exit 1
    fi

    if [ ! -d "$chrome_data_folder/data$i" ];then
      echo "Folder data$i does not exist. Exiting.."
      exit 1
    fi

    # Deleting data and starting containers
    chmod -R 777 $chrome_data_folder/data$i
    rm -rf $chrome_data_folder/data$i/*
    chown -R 911:911 $chrome_profile_data
    cp -r $chrome_profile_data $chrome_data_folder/data$i
    chown -R 911:911 $chrome_data_folder/data$i
    docker update --restart=always $container
    docker start $container
  done

elif [[ "$1" == "--restartFirefox" ]]; then
  firefox_profile_data="firefoxprofiledata"
  i=0
  for container in `cat firefoxcontainers.txt`
  do
    i=`expr $i + 1`
    # Check if container exists
    docker update --restart=no $container
    docker stop $container
    # Firefox with direct connection
    if [ -d "firefoxdata/data" ];then
      chmod -R 777 firefoxdata/data
      rm -rf firefoxdata/data/*
      cp -r $firefox_profile_data/* firefoxdata/data/
      chmod -R 777 firefoxdata/data
      docker update --restart=always $container
      docker start $container
      exit 1
    fi

    if [ ! -d "firefoxdata/data$i" ];then
      echo "Folder data$i does not exist. Exiting.."
      exit 1
    fi

    # Deleting data and starting containers
    chmod -R 777 firefoxdata/data$i
    rm -rf firefoxdata/data$i/*
    cp -r $firefox_profile_data/* firefoxdata/data$i/
    chmod -R 777 firefoxdata/data$i
    docker update --restart=always $container
    docker start $container
  done
fi
