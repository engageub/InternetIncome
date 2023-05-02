#!/bin/bash

##################################################################################
# Author: engageub                                                               #
# Description: This script lets you earn passive income by sharing your internet #
# connection. It also supports multiple proxies with multiple accounts.          #
# Script Name: Internet Income (Supports Proxies)                                # 
# Script Link: https://github.com/engageub/InternetIncome                        #
# DISCLAIMER: This script is provided "as is" and without warranty of any kind.  #
# The author makes no warranties, express or implied, that this script is free of#
# errors, defects, or suitable for any particular purpose. The author shall not  #
# be liable for any damages suffered by any user of this script, whether direct, #
# indirect, incidental, consequential, or special, arising from the use of or    #
# inability to use this script or its documentation, even if the author has been #
# advised of the possibility of such damages.                                    #
##################################################################################

######### DO NOT EDIT THE CODE BELOW UNLESS YOU KNOW WHAT YOU ARE DOING  #########
# Colours
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
NOCOLOUR="\033[0m"

# File names 
properties_file="properties.conf"
banner_file="banner.jpg"
proxies_file="proxies.txt"
containers_file="containers.txt"
earnapp_file="earnapp.txt"
networks_file="networks.txt"
bitping_folder=".bitping"

# Use banner if exists
if [ -f "$banner_file" ]; then
  for count in {1..3}
  do
    clear
    echo -e "${RED}"
    cat $banner_file
    sleep 0.5
    clear
    echo -e "${GREEN}"
    cat $banner_file
    sleep 0.5
    clear
    echo -e "${YELLOW}"
    cat $banner_file
    sleep 0.5
  done
  echo -e "${NOCOLOUR}"
fi

# Login to bitping
login_bitping() {
  if [ "$BITPING" = true ]; then
    if [ ! -d $bitping_folder ]; then
      echo -e "${GREEN}Enter your bitping email and password below..${NOCOLOUR}"
      echo -e "${RED}Press CTRL + C after it is connected..${NOCOLOUR}"	
      mkdir $bitping_folder
      sleep 5
      sudo docker run -it --rm --platform=linux/amd64 --mount type=bind,source="$PWD/$bitping_folder/",target=/root/.bitping bitping/bitping-node:latest
    fi
  fi
}

# Start all containers 
start_containers() {

  i=$1
  proxy=$2

  if [[ "$ENABLE_LOGS" = false ]]; then
    LOGS_PARAM="--log-driver none"
    TUN_LOG_PARAM="silent"
  else
    TUN_LOG_PARAM="info"
  fi

  if [[ $i && $proxy ]]; then
    NETWORK=tunnetwork$i
    NETWORK_TUN="--network=container:tun$i"
    if sudo docker network inspect ${NETWORK} > /dev/null 2>&1; then
      echo -e "${RED}Network '${NETWORK}' already exists ${NOCOLOUR}"
    else
      echo -e "${GREEN}Network '${NETWORK}' doesn't exist; creating it${NOCOLOUR}"
      if CONTAINER_ID=$(sudo docker network create ${NETWORK}); then
        echo "$CONTAINER_ID" |tee -a $networks_file
      else
        echo -e "${RED}Failed to create network. Exiting..${NOCOLOUR}"
        exit 1
      fi
    fi
    sleep 1
    # Starting tun containers
    if CONTAINER_ID=$(sudo docker run --name tun$i $LOGS_PARAM --restart=always --network $NETWORK -e LOGLEVEL=$TUN_LOG_PARAM -e PROXY=$proxy -e TUN_EXCLUDED_ROUTES=8.8.8.8,8.8.4.4,208.67.222.222,208.67.220.220,1.1.1.1,1.0.0.1 -v '/dev/net/tun:/dev/net/tun' --cap-add=NET_ADMIN -d xjasonlyu/tun2socks); then
      echo "$CONTAINER_ID" |tee -a $containers_file
    else
      echo -e "${RED}Failed to start container for proxy. Exiting..${NOCOLOUR}"
      exit 1
    fi
    sleep 1
  fi
  
  # Starting BitPing container
  if [ "$BITPING" = true ]; then
    echo -e "${GREEN}Starting Bitping container..${NOCOLOUR}"
    if CONTAINER_ID=$(sudo docker run -d --restart=always --platform=linux/amd64 $NETWORK_TUN $LOGS_PARAM --mount type=bind,source="$PWD/$bitping_folder/",target=/root/.bitping bitping/bitping-node:latest); then
      echo "$CONTAINER_ID" |tee -a $containers_file 
    else
      echo -e "${RED}Failed to start container for BitPing..${NOCOLOUR}"
    fi
  else
    echo -e "${RED}BitPing Node is not enabled. Ignoring BitPing..${NOCOLOUR}"
  fi

  # Starting Repocket container
  if [[ $REPOCKET_EMAIL && $REPOCKET_API ]]; then
    echo -e "${GREEN}Starting Repocket container..${NOCOLOUR}"
    if CONTAINER_ID=$(sudo docker run -d --restart=always $NETWORK_TUN $LOGS_PARAM -e RP_EMAIL=$REPOCKET_EMAIL -e RP_API_KEY=$REPOCKET_API repocket/repocket); then
      echo "$CONTAINER_ID" |tee -a $containers_file 
    else
      echo -e "${RED}Failed to start container for Repocket..${NOCOLOUR}"
    fi
  else
    echo -e "${RED}Repocket Email or Api is not configured. Ignoring Repocket..${NOCOLOUR}"
  fi

  # Starting Traffmonetizer container
  if [[ $TRAFFMONETIZER_TOKEN ]]; then
    echo -e "${GREEN}Starting Traffmonetizer container..${NOCOLOUR}"
    if CONTAINER_ID=$(sudo  docker run -d --platform=linux/amd64 --restart=always $LOGS_PARAM --name trafff$i $NETWORK_TUN traffmonetizer/cli start accept --token $TRAFFMONETIZER_TOKEN); then
      echo "$CONTAINER_ID" |tee -a $containers_file 
    else
      echo -e "${RED}Failed to start container for Traffmonetizer..${NOCOLOUR}"
    fi
  else
    echo -e "${RED}Traffmonetizer Token is not configured. Ignoring Traffmonetizer..${NOCOLOUR}"
  fi

  # Starting ProxyRack container
  if [[ $PROXY_RACK_API ]]; then
    echo -e "${GREEN}Starting ProxyRack container..${NOCOLOUR}"
    if CONTAINER_ID=$(sudo docker run -d --platform=linux/amd64 $NETWORK_TUN $LOGS_PARAM --restart=always --name proxyrack$i -e api_key=$PROXY_RACK_API -e device_name=$DEVICE_NAME$i proxyrack/pop); then
      echo "$CONTAINER_ID" |tee -a $containers_file 
    else
      echo -e "${RED}Failed to start container for ProxyRack..${NOCOLOUR}"
  fi  
  else
    echo -e "${RED}ProxyRack Api is not configured. Ignoring ProxyRack..${NOCOLOUR}"
  fi

  # Starting IPRoyals pawns container
  if [[ $IPROYALS_EMAIL && $IPROYALS_PASSWORD ]]; then
    echo -e "${GREEN}Starting IPRoyals container..${NOCOLOUR}"
    if CONTAINER_ID=$(sudo docker run -d --restart=always $LOGS_PARAM $NETWORK_TUN iproyal/pawns-cli:latest -email=$IPROYALS_EMAIL -password=$IPROYALS_PASSWORD -device-name=$DEVICE_NAME$i -device-id=$DEVICE_NAME$i -accept-tos); then
      echo "$CONTAINER_ID" |tee -a $containers_file 
    else
      echo -e "${RED}Failed to start container for IPRoyals..${NOCOLOUR}"
    fi   
  else
    echo -e "${RED}IPRoyals Email or Password is not configured. Ignoring IPRoyals..${NOCOLOUR}"
  fi
  
  # Starting Honeygain container
  if [[ $HONEYGAIN_EMAIL && $HONEYGAIN_PASSWORD ]]; then
    echo -e "${GREEN}Starting Honeygain container..${NOCOLOUR}"
    if CONTAINER_ID=$(sudo docker run -d $NETWORK_TUN $LOGS_PARAM --restart=always --platform=linux/amd64 honeygain/honeygain -tou-accept -email $HONEYGAIN_EMAIL -pass $HONEYGAIN_PASSWORD -device $DEVICE_NAME$i); then
      echo "$CONTAINER_ID" |tee -a $containers_file 
    else
      echo -e "${RED}Failed to start container for Honeygain..${NOCOLOUR}"
  fi
  else
    echo -e "${RED}Honeygain Email or Password is not configured. Ignoring Honeygain..${NOCOLOUR}"
  fi

  # Starting Peer2Profit container
  if [[ $PEER2PROFIT_EMAIL ]]; then
    echo -e "${GREEN}Starting Peer2Profit container..${NOCOLOUR}"
    if CONTAINER_ID=$(sudo docker run -d $NETWORK_TUN --restart always -e P2P_EMAIL=$PEER2PROFIT_EMAIL --name peer2profit$i  peer2profit/peer2profit_linux:latest); then
      echo "$CONTAINER_ID" |tee -a $containers_file
    else
      echo -e "${RED}Failed to start container for Peer2Profit..${NOCOLOUR}"
    fi   
  else
    echo -e "${RED}Peer2Profit Email is not configured. Ignoring Peer2Profit..${NOCOLOUR}"
  fi

  # Starting PacketStream container
  if [[ $PACKETSTREAM_CID ]]; then
    echo -e "${GREEN}Starting PacketStream container..${NOCOLOUR}"
    if CONTAINER_ID=$(sudo docker run -d $NETWORK_TUN $LOGS_PARAM --restart always -e CID=$PACKETSTREAM_CID -e http_proxy=$proxy -e https_proxy=$proxy --name packetstream$i packetstream/psclient:latest); then
      echo "$CONTAINER_ID" |tee -a $containers_file 
    else
      echo -e "${RED}Failed to start container for PacketStream..${NOCOLOUR}"
    fi   
  else
    echo -e "${RED}PacketStream CID is not configured. Ignoring PacketStream..${NOCOLOUR}"
  fi

  # Starting Proxylite container
  if [[ $PROXYLITE_USER_ID ]]; then
    echo -e "${GREEN}Starting Proxylite container..${NOCOLOUR}"
    if CONTAINER_ID=$(sudo docker run -d --platform=linux/amd64 $NETWORK_TUN $LOGS_PARAM  -e USER_ID=$PROXYLITE_USER_ID --restart=always  --name proxylite$i proxylite/proxyservice); then
      echo "$CONTAINER_ID" |tee -a $containers_file 
    else
      echo -e "${RED}Failed to start container for Proxylite..${NOCOLOUR}"
    fi 
  else
    echo -e "${RED}Proxylite is not configured. Ignoring Proxylite..${NOCOLOUR}"
  fi

  # Starting Earnapp container
  if [ "$EARNAPP" = true ]; then
    echo -e "${GREEN}Starting Earnapp container..${NOCOLOUR}"
    echo -e "${GREEN}Copy the following node url and paste in your earnapp dashboard${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $earnapp_file in the same folder${NOCOLOUR}"
    RANDOM=$(date +%s)
    RANDOM_ID="$(echo -n "$RANDOM" | md5sum | cut -c1-32)"
    date_time=`date "+%D %T"`
    printf "$date_time https://earnapp.com/r/sdk-node-%s\n" "$RANDOM_ID" | tee -a $earnapp_file
    if CONTAINER_ID=$(sudo docker run -d --platform=linux/amd64 $LOGS_PARAM --restart=always $NETWORK_TUN -e EARNAPP_UUID=sdk-node-$RANDOM_ID --name earnapp$i fazalfarhan01/earnapp:lite); then
      echo "$CONTAINER_ID" |tee -a $containers_file 
    else
      echo -e "${RED}Failed to start container for Earnapp..${NOCOLOUR}"
    fi  
  else
    echo -e "${RED}Earnapp is not enabled. Ignoring Earnapp..${NOCOLOUR}"
  fi

} 

if [[ "$1" == "--start" ]]; then
  echo -e "\n\nStarting.."
  # Check if the properties file exists
  if [ ! -f "$properties_file" ]; then
    echo -e "${RED}Properties file $properties_file does not exist, exiting..${NOCOLOUR}"
    exit 1
  fi

  # Read the properties file and export variables to the current shell
  while IFS='=' read -r key value; do
    # Ignore lines that start with #
    if [[ $key != '#'* ]]; then
        # Ignore lines without a value after =
        if [[ -n $value ]]; then
            # Replace variables with their values
            value=$(eval "echo $value")
            # Export the key-value pairs as variables
            export "$key"="$value"
        fi
    fi
  done < $properties_file

  # Setting Device name
  if [[ ! $DEVICE_NAME ]]; then
    echo -e "${RED}Device Name is not configured. Using default name ${NOCOLOUR}ubuntu"
    DEVICE_NAME=ubuntu
  fi
  
  #Login to bitping to set credentials
  login_bitping

  if [ "$USE_PROXIES" = true ]; then
    if [ ! -f "$proxies_file" ]; then
      echo -e "${RED}Proxies file $proxies_file does not exist, exiting..${NOCOLOUR}"
      exit 1
    fi
    i=0;
    while IFS= read -r line; do
      if [[ "$line" =~ ^[^#].* ]]; then
        i=`expr $i + 1`
        start_containers "$i" "$line"
      fi
    done < $proxies_file
  else
    start_containers
  fi
fi

if [[ "$1" == "--delete" ]]; then
   echo -e "\n\nDeleting Containers and networks.."
  if [ ! -f "$containers_file" ]; then
     echo -e "${RED}Containers file $containers_file does not exist, exiting..${NOCOLOUR}"
     exit 1
  fi
  for i in `cat $containers_file`
  do 
  
    # Check if container exists
    if sudo docker inspect $i >/dev/null 2>&1; then
      # Update container not to restart
      sudo docker update --restart=no $i
      # Check container status
      status=$(sudo docker inspect -f '{{.State.Status}}' $i)
      if [ "$status" != "exited" ]; then
        # Stop the container
        sudo docker stop $i
      fi
      # Remove container
      sudo docker rm $i
    else
      echo "Container $i does not exist"
    fi
  done
  # Delete the container file
  rm $containers_file
  # Delete earnapp file
  if [ -f "$earnapp_file" ]; then
    rm $earnapp_file
  fi 
  
  # Delete networks
  if [ -f "$networks_file" ]; then
    for i in `cat $networks_file`
    do
      # Check if network exists and delete
      if sudo docker network inspect $i > /dev/null 2>&1; then
        sudo docker network rm $i
      else
        echo "Network $i does not exist"
      fi
    done
    # Delete network file
    rm $networks_file
  fi
  
  # Delete Bitping Directory
  if [ -d $bitping_folder ]; then 
    rm -Rf $bitping_folder;
  fi

fi

if [[ ! "$1" ]]; then
  echo "No option provided. Use --start or --delete to execute"
fi
