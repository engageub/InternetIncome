#!/bin/bash

if [[ "$1" == "--restartAdnade" ]]; then
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
      sleep 300
      docker start $container
      exit 1
    fi
    if [ ! -d "/chrome/$chrome_data_folder/data$i" ];then
      echo "Folder data$i does not exist. Exiting.."
      exit 1
    fi
    # Deleting data and starting containers
    chmod -R 777 /chrome/$chrome_data_folder/data$i
    rm -rf /chrome/$chrome_data_folder/data$i/*
    chown -R 911:911 /chrome/$chrome_profile_data
    cp -r /chrome/$chrome_profile_data /chrome/$chrome_data_folder/data$i
    chown -R 911:911 /chrome/$chrome_data_folder/data$i
    docker update --restart=always $container
    if [ $i == 1 ];then
      sleep 300
    fi
    docker start $container
  done

elif [[ "$1" == "--restartAdnadeFirefox" ]]; then
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
    # Deleting data and starting containers
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
    if [ -d "/chrome/$chrome_data_folder/data" ];then
      chmod -R 777 /chrome/$chrome_data_folder/data
      rm -rf /chrome/$chrome_data_folder/data/*
      chown -R 911:911 /chrome/$chrome_profile_data
      cp -r /chrome/$chrome_profile_data /chrome/$chrome_data_folder/data
      chown -R 911:911 /chrome/$chrome_data_folder/data
      docker update --restart=always $container
      docker start $container
      exit 1
    fi
    if [ ! -d "/chrome/$chrome_data_folder/data$i" ];then
      echo "Folder data$i does not exist. Exiting.."
      exit 1
    fi
    # Deleting data and starting containers
    chmod -R 777 /chrome/$chrome_data_folder/data$i
    rm -rf /chrome/$chrome_data_folder/data$i/*
    chown -R 911:911 /chrome/$chrome_profile_data
    cp -r /chrome/$chrome_profile_data /chrome/$chrome_data_folder/data$i
    chown -R 911:911 /chrome/$chrome_data_folder/data$i
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
    if [ -d "/firefox/firefoxdata/data" ];then
      chmod -R 777 /firefox/firefoxdata/data
      rm -rf /firefox/firefoxdata/data/*
      cp -r /firefox/$firefox_profile_data/* firefoxdata/data/
      chmod -R 777 /firefox/firefoxdata/data
      docker update --restart=always $container
      sleep 300
      docker start $container
      exit 1
    fi
    if [ ! -d "/firefox/firefoxdata/data$i" ];then
      echo "Folder data$i does not exist. Exiting.."
      exit 1
    fi
    # Deleting data and starting containers
    chmod -R 777 /firefox/firefoxdata/data$i
    rm -rf /firefox/firefoxdata/data$i/*
    cp -r /firefox/$firefox_profile_data/* firefoxdata/data$i/
    chmod -R 777 /firefox/firefoxdata/data$i
    docker update --restart=always $container
    if [ $i == 1 ];then
      sleep 300
    fi
    docker start $container
  done

elif [[ "$1" == "--restartEarnapp" ]]; then
  # Truncate log files before restarting
  find earnappdata -type f -name "*.log" -exec truncate -s 0 {} +
  for container in `cat containernames.txt | grep ^earnapp`
  do
    docker restart $container
  done

elif [[ "$1" == "--restartProxybase" ]]; then
  # Restarting Proxybase Nodes
  for container in `cat containernames.txt | grep ^proxybase`
  do
    docker restart $container
  done

elif [[ "$1" == "--restartURnetwork" ]]; then
  # Restarting URnetwork Nodes
  for container in `cat containernames.txt | grep ^urnetwork`
  do
    docker restart $container
  done
  
fi
