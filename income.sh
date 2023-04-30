#!/bin/bash

##################################################################################
# Author: engageub                                                               #
# Description: This script lets you earn passive income by sharing your internet #
# connection. It also supports multiple proxies with multiple accounts.          #
# Script Name: Internet Cash (Supports Proxies)                                  # 
#                                                                                #
# DISCLAIMER: This script is provided "as is" and without warranty of any kind.  #
# The author makes no warranties, express or implied, that this script is free of#
# errors, defects, or suitable for any particular purpose. The author shall not  #
# be liable for any damages suffered by any user of this script, whether direct, #
# indirect, incidental, consequential, or special, arising from the use of or    #
# inability to use this script or its documentation, even if the author has been #
# advised of the possibility of such damages.                                    #
##################################################################################

######### DO NOT EDIT THE CODE BELOW UNLESS YOU KNOW WHAT YOU ARE DOING  #########
#Colours
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
NOCOLOUR="\033[0m"

#Files required 
properties_file="properties.conf"
banner_file="banner.txt"
proxies_file="proxies.txt"

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
  echo -e "\n\nStarting.."
fi

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

#Setting Device name
if [[ ! $DEVICE_NAME ]]; then
  echo -e "${RED}Device Name is not configured. Using default name ${NOCOLOUR}ubuntu"
  DEVICE_NAME=ubuntu
fi


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
    if sudo docker network inspect ${NETWORK} > /dev/null 2>&1
    then
      echo -e "${RED}Network '${NETWORK}' already exists ${NOCOLOUR}"
    else
      echo -e "${RED}Network '${NETWORK}' doesn't exist; creating it${NOCOLOUR}"
      sudo docker network create ${NETWORK} > /dev/null
    fi
    sleep 1
    #Starting tun containers 
    sudo docker run --name tun$i $LOGS_PARAM --restart=always --network $NETWORK -e LOGLEVEL=$TUN_LOG_PARAM -e PROXY=$proxy -e TUN_EXCLUDED_ROUTES=8.8.8.8,8.8.4.4,208.67.222.222,208.67.220.220,1.1.1.1,1.0.0.1 -v '/dev/net/tun:/dev/net/tun' --cap-add=NET_ADMIN -d xjasonlyu/tun2socks
    sleep 1
  fi
    
  #Starting Repocket container
  if [[ $REPOCKET_EMAIL && $REPOCKET_API ]]; then
    echo -e "${GREEN}Starting Repocket container..${NOCOLOUR}"
    sudo docker run -d --restart=always $NETWORK_TUN $LOGS_PARAM -e RP_EMAIL=$REPOCKET_EMAIL -e RP_API_KEY=$REPOCKET_API repocket/repocket
  else
    echo -e "${RED}Repocket Email or Api is not configured. Ignoring Repocket..${NOCOLOUR}"
  fi

  #Starting Traffmonetizer container
  if [[ $TRAFFMONETIZER_TOKEN ]]; then
    echo -e "${GREEN}Starting Traffmonetizer container..${NOCOLOUR}"
    sudo  docker run -d --platform=linux/amd64 --restart=always $LOGS_PARAM --name trafff$i $NETWORK_TUN traffmonetizer/cli start accept --token $TRAFFMONETIZER_TOKEN
  else
    echo -e "${RED}Traffmonetizer Token is not configured. Ignoring Traffmonetizer..${NOCOLOUR}"
  fi

  #Starting ProxyRack container
  if [[ $PROXY_RACK_API ]]; then
    echo -e "${GREEN}Starting ProxyRack container..${NOCOLOUR}"
    sudo docker run -d --platform=linux/amd64 $NETWORK_TUN $LOGS_PARAM --restart=always --name proxyrack$i -e api_key=$PROXY_RACK_API -e device_name=$DEVICE_NAME$i proxyrack/pop
  else
    echo -e "${RED}ProxyRack Api is not configured. Ignoring ProxyRack..${NOCOLOUR}"
  fi

  #Starting IPRoyals pawns container
  if [[ $IPROYALS_EMAIL && $IPROYALS_PASSWORD ]]; then
    echo -e "${GREEN}Starting IPRoyals container..${NOCOLOUR}"
    sudo docker run -d --restart=always $LOGS_PARAM $NETWORK_TUN iproyal/pawns-cli:latest -email=$IPROYALS_EMAIL -password=$IPROYALS_PASSWORD -device-name=$DEVICE_NAME$i -device-id=$DEVICE_NAME$i -accept-tos
  else
    echo -e "${RED}IPRoyals Email or Password is not configured. Ignoring IPRoyals..${NOCOLOUR}"
  fi
  
  #Starting Honeygain container
  if [[ $HONEYGAIN_EMAIL && $HONEYGAIN_PASSWORD ]]; then
    echo -e "${GREEN}Starting Honeygain container..${NOCOLOUR}"
    sudo docker run -d $NETWORK_TUN $LOGS_PARAM --restart=always --platform=linux/amd64 honeygain/honeygain -tou-accept -email $HONEYGAIN_EMAIL -pass $HONEYGAIN_PASSWORD -device $DEVICE_NAME$i
  else
    echo -e "${RED}Honeygain Email or Password is not configured. Ignoring Honeygain..${NOCOLOUR}"
  fi

  #Starting Peer2Profit container
  if [[ $PEER2PROFIT_EMAIL ]]; then
    echo -e "${GREEN}Starting Peer2Profit container..${NOCOLOUR}"
    sudo docker run -d $NETWORK_TUN --restart always -e P2P_EMAIL=$PEER2PROFIT_EMAIL --name peer2profit$i  peer2profit/peer2profit_linux:latest
  else
    echo -e "${RED}Peer2Profit Email is not configured. Ignoring Peer2Profit..${NOCOLOUR}"
  fi

  #Starting PacketStream container
  if [[ $PACKETSTREAM_CID ]]; then
    echo -e "${GREEN}Starting PacketStream container..${NOCOLOUR}"
    sudo docker run -d $NETWORK_TUN $LOGS_PARAM --restart always -e CID=$PACKETSTREAM_CID -e http_proxy=$proxy -e https_proxy=$proxy --name packetstream$i packetstream/psclient:latest
  else
    echo -e "${RED}PacketStream CID is not configured. Ignoring PacketStream..${NOCOLOUR}"
  fi

  #Starting Proxylite container
  if [[ $PROXYLITE_USER_ID ]]; then
    echo -e "${GREEN}Starting Proxylite container..${NOCOLOUR}"
    sudo docker run -d --platform=linux/amd64 $NETWORK_TUN $LOGS_PARAM  -e USER_ID=$PROXYLITE_USER_ID --restart=always  --name proxylite$i proxylite/proxyservice
  else
    echo -e "${RED}Proxylite is not configured. Ignoring Proxylite..${NOCOLOUR}"
  fi

  #Starting Earnapp container
  if [ "$EARNAPP" = true ]; then
    echo -e "${GREEN}Starting Earnapp container..${NOCOLOUR}"
    echo -e "${GREEN}Copy the following node url and paste in your earnapp dashboard${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file earnapp.txt in the same folder${NOCOLOUR}"
    RANDOM=$(date +%s)
    RANDOM_ID="$(echo -n "$RANDOM" | md5sum | cut -c1-32)"
    date_time=`date "+%D %T"`
    printf "$date_time https://earnapp.com/r/sdk-node-%s\n" "$RANDOM_ID" | tee -a earnapp.txt
    sudo docker run -d --platform=linux/amd64 $LOGS_PARAM --restart=always $NETWORK_TUN -e EARNAPP_UUID=sdk-node-$RANDOM_ID --name earnapp$i fazalfarhan01/earnapp:lite
  else
    echo -e "${RED}Earnapp is not enabled. Ignoring Earnapp..${NOCOLOUR}"
  fi

} 


if [ "$USE_PROXIES" = true ]; then

  if [ ! -f "$proxies_file" ]; then
    echo -e "${RED}Proxies file $proxies_file does not exist, exiting..${NOCOLOUR}"
    exit 1
  fi
  
  i=0;
  for proxy in `cat proxies.txt`
  do
    if [[ "$line" =~ ^[^#].* ]]; then
      i=`expr $i + 1`
      start_containers "$i" "$proxy"
    fi
  done
else
  start_containers
fi
