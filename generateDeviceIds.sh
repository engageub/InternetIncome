#!/bin/bash

#Script to get device Ids from containers
containers_file="containernames.txt"
cloud_collab_file="cloudcollab.txt"
earn_app_file="testing.txt"

if [ ! -f $containers_file ]; then
  echo "$containers_file file does not exist. Exiting.."
  exit 1
fi

if [ -f $cloud_collab_file ]; then
  rm $cloud_collab_file
fi

if [ -f $earn_app_file ]; then
  rm $earn_app_file
fi

# Get device Ids from containers
for container in `cat $containers_file`
do
  if [[ $container == "cloudcollab"* ]]; then
    sudo docker exec  $container cat /root/.config/CloudCollab/deviceid | od -A n -v -t x1 | tr -d ' ' | tee -a $cloud_collab_file
  fi
  if [[ $container == "testing"* ]]; then
    sudo docker exec -it $container earnapp showid | tee -a $earn_app_file
  fi
done

