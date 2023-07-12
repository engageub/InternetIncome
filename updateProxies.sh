#!/bin/bash

#Script to update proxies and restart instances if proxies are updated in proxies.txt
containers_file="containers.txt"
proxies_file="proxies.txt"
tun_containers_file="tuncontainers.txt"
updated_proxies_file="updatedproxies.txt"

if [ -f $tun_containers_file ]; then
  rm $tun_containers_file
fi

if [ -f $updated_proxies_file ]; then
  rm $updated_proxies_file
fi

if [ ! -f $containers_file ]; then
  echo "$containers_file file does not exist. Exiting.."
  exit 1
fi

if [ ! -f $proxies_file ]; then
  echo "$proxies_file file does not exist. Exiting.."
  exit 1
fi

# Get tun containers and stop other containers
for container in `cat $containers_file`
do
if sudo docker inspect $container >/dev/null 2>&1; then
  container_image=`sudo docker inspect --format='{{.Config.Image}}' $container`
  if [[ $container_image == "xjasonlyu/tun2socks"* ]]; then
    echo $container | tee -a $tun_containers_file
  fi
fi
done

# Store formatted proxies in a new file
while IFS= read -r line || [ -n "$line" ]; do
      if [[ "$line" =~ ^[^#].* ]]; then
        i=`expr $i + 1`
       echo $line | tee -a $updated_proxies_file
      fi
done < $proxies_file

if [ ! -f $tun_containers_file ]; then
  echo "$tun_containers_file file does not exist. Exiting.."
  exit 1
fi

if [ ! -f $updated_proxies_file ]; then
  echo "$updated_proxies_file file does not exist. Exiting.."
  exit 1
fi

# Match the number of containers with proxies 
if [ `cat $tun_containers_file|wc -l` == `cat $updated_proxies_file|wc -l` ]; then
echo "Updating Proxies"
while read container_id <&3 && read container_proxy <&4; do
  container_image=`sudo docker inspect --format='{{.Config.Image}}' $container_id`
  if [[ $container_image == "xjasonlyu/tun2socks"* ]]; then
    sudo docker exec $container_id sh -c "sed -i \"\#--proxy#s#.*#    --proxy ${container_proxy//\//\\\\/} \\\\\#\" entrypoint.sh"
    sudo docker exec $container_id sh -c "sed -i \"\|exec tun2socks|s#.*#echo 'nameserver 8.8.8.8' > /etc/resolv.conf;ip rule add iif lo ipproto udp dport 53 lookup main;exec tun2socks \\\\\#\" entrypoint.sh"
  fi
done 3<$tun_containers_file 4<$updated_proxies_file
else
  echo "Number of containers do not match proxies. Exiting.."
  exit 1
fi

# Stop all containers
for container in `cat $containers_file`
do
if sudo docker inspect $container >/dev/null 2>&1; then
  sudo docker stop $container
fi
done

echo "Waiting for 5 seconds before starting"
sleep 5

# Restart/Start all containers
echo "Restarting Containers"
for container in `cat $containers_file`
do
if sudo docker inspect $container >/dev/null 2>&1; then
  status=$(sudo docker inspect -f '{{.State.Status}}' $container)
  if [ "$status" != "exited" ]; then
    sudo docker restart $container
  else
    sudo docker start $container
  fi
fi
done
