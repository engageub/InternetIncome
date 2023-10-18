#!/bin/bash

#Script to generate device Ids
containers_file="containernames.txt"
cloud_collab_file="cloudcollab.txt"

if [ ! -f $containers_file ]; then
  echo "$containers_file file does not exist. Exiting.."
  exit 1
fi

if [ -f $cloud_collab_file ]; then
  rm $cloud_collab_file
fi

# Get device Ids from containers
for container in `cat $containers_file`
do
  if [[ $container == "cloudcollab"* ]]; then
        sudo docker exec  $container cat /root/.config/CloudCollab/deviceid | od -A n -v -t x1 | tr -d ' ' | tee -a $cloud_collab_file
  fi
done

