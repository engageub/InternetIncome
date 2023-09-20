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
container_names_file="containernames.txt"
earnapp_file="earnapp.txt"
earnapp_data_folder="earnappdata"
networks_file="networks.txt"
mysterium_file="mysterium.txt"
mysterium_data_folder="mysterium-data"
ebesucher_file="ebesucher.txt"
adnade_file="adnade.txt"
firefox_containers_file="firefoxcontainers.txt"
bitping_folder=".bitping"
firefox_data_folder="firefoxdata"
firefox_profile_data="firefoxprofiledata"
firefox_profile_zipfile="firefoxprofiledata.zip"
traffmonetizer_data_folder="traffmonetizerdata"
proxyrack_data_folder="proxyrackdata"
restart_firefox_file="restartFirefox.sh"
required_files=($banner_file $properties_file $firefox_profile_zipfile $restart_firefox_file)
files_to_be_removed=($containers_file $container_names_file $networks_file $mysterium_file $ebesucher_file $adnade_file $firefox_containers_file)
folders_to_be_removed=($bitping_folder $firefox_data_folder $firefox_profile_data $earnapp_data_folder)
back_up_folders=($proxyrack_data_folder $traffmonetizer_data_folder $mysterium_data_folder)
back_up_files=($earnapp_file)

container_pulled=false

# Mysterium and ebesucher first port
mysterium_first_port=2000
ebesucher_first_port=3000
adnade_first_port=4000


#Unique Id
RANDOM=$(date +%s)
UNIQUE_ID="$(echo -n "$RANDOM" | md5sum | cut -c1-32)"

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

# Define a function to check for open ports
check_open_ports() {
  local first_port=$1
  local num_ports=$2
  port_range=$(seq $first_port $((first_port+num_ports-1)))
  open_ports=0
  
  for port in $port_range; do
    nc -z localhost $port > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      open_ports=$((open_ports+1))
    fi
  done

  while [ $open_ports -gt 0 ]; do
    first_port=$((first_port+num_ports))
    port_range=$(seq $first_port $((first_port+num_ports-1)))
    open_ports=0
    for port in $port_range; do
      nc -z localhost $port > /dev/null 2>&1
      if [ $? -eq 0 ]; then
        open_ports=$((open_ports+1))
      fi
    done
  done

  echo $first_port
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
    NETWORK_TUN="--network=container:tun$UNIQUE_ID$i"
        
    if [ "$MYSTERIUM" = true ]; then
      mysterium_first_port=$(check_open_ports $mysterium_first_port 1)
      if ! expr "$mysterium_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $mysterium_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Mysterium node. Resolve or disable Mysterium to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      mysterium_port="-p $mysterium_first_port:4449 "
    fi
    
    if [[ $EBESUCHER_USERNAME ]]; then
      ebesucher_first_port=$(check_open_ports $ebesucher_first_port 1)
      if ! expr "$ebesucher_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $ebesucher_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Ebesucher. Resolve or disable Ebesucher to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      ebesucher_port="-p $ebesucher_first_port:5800 "
    fi

     if [[ $ADNADE_USERNAME ]]; then
      adnade_first_port=$(check_open_ports $adnade_first_port 1)
      if ! expr "$adnade_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $adnade_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Adnade. Resolve or disable Adnade to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      adnade_port="-p $adnade_first_port:5800 "
    fi
    
    combined_ports=$mysterium_port$ebesucher_port$adnade_port
    echo -e "${GREEN}Starting Proxy container..${NOCOLOUR}"
    # Starting tun containers
    if [ "$container_pulled" = false ]; then
      sudo docker pull xjasonlyu/tun2socks:v2.5.0
    fi
    if CONTAINER_ID=$(sudo docker run --name tun$UNIQUE_ID$i $LOGS_PARAM --restart=always -e LOGLEVEL=$TUN_LOG_PARAM -e PROXY=$proxy -v '/dev/net/tun:/dev/net/tun' --cap-add=NET_ADMIN $combined_ports -d xjasonlyu/tun2socks:v2.5.0); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "tun$UNIQUE_ID$i" | tee -a $container_names_file
      sudo docker exec $CONTAINER_ID sh -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf;ip rule add iif lo ipproto udp dport 53 lookup main;'
    else
      echo -e "${RED}Failed to start container for proxy. Exiting..${NOCOLOUR}"
      exit 1
    fi
    sleep 1
  fi
  
  # Starting Mysterium container
  if [ "$MYSTERIUM" = true ]; then
    echo -e "${GREEN}Starting Mysterium container..${NOCOLOUR}"
    echo -e "${GREEN}Copy the following node url and paste in your browser${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $mysterium_file in the same folder${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull mysteriumnetwork/myst:latest  
    fi
    if [[  ! $proxy ]]; then
      mysterium_first_port=$(check_open_ports $mysterium_first_port 1)
      if ! expr "$mysterium_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $mysterium_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Mysterium node. Resolve or disable Mysterium to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      myst_port="-p $mysterium_first_port:4449"
    fi
    mkdir -p $PWD/$mysterium_data_folder/node$i
    sudo chmod -R 777 $PWD/$mysterium_data_folder/node$i
    if CONTAINER_ID=$(sudo docker run -d --name myst$UNIQUE_ID$i --cap-add=NET_ADMIN $NETWORK_TUN $LOGS_PARAM -v $PWD/$mysterium_data_folder/node$i:/var/lib/mysterium-node --restart unless-stopped $myst_port mysteriumnetwork/myst:latest service --agreed-terms-and-conditions); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "myst$UNIQUE_ID$i" | tee -a $container_names_file 
      echo "http://127.0.0.1:$mysterium_first_port" |tee -a $mysterium_file
      mysterium_first_port=`expr $mysterium_first_port + 1`
    else
      echo -e "${RED}Failed to start container for Mysterium..${NOCOLOUR}"
    fi
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Mysterium Node is not enabled. Ignoring Mysterium..${NOCOLOUR}"
    fi
  fi
  
  # Starting Ebesucher container
  if [[ $EBESUCHER_USERNAME ]]; then
    echo -e "${GREEN}Starting Ebesucher container..${NOCOLOUR}"
    echo -e "${GREEN}Copy the following node url and paste in your browser if required..${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $ebesucher_file in the same folder${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull jlesage/firefox
      
      # Exit, if restart script is missing
      if [ ! -f "$PWD/$restart_firefox_file" ];then
        echo -e "${RED}Firefox restart script does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi 
      
      # Exit, if firefox profile zip file is missing
      if [ ! -f "$PWD/$firefox_profile_zipfile" ];then
        echo -e "${RED}Firefox profile file does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi
      
      # Unzip the file
      unzip $firefox_profile_zipfile
      
      # Exit, if firefox profile data is missing
      if [ ! -d "$PWD/$firefox_profile_data" ];then
        echo -e "${RED}Firefox Data folder does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi
      
      if CONTAINER_ID=$(sudo docker run -d --name dind$UNIQUE_ID$i $LOGS_PARAM --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/usr/bin/docker -v $PWD:/firefox docker:18.06.2-dind /bin/sh -c 'apk add --no-cache bash && cd /firefox && chmod +x /firefox/restartFirefox.sh && while true; do sleep 3600; /firefox/restartFirefox.sh; done'); then
        echo "Firefox restart container started"
        echo "$CONTAINER_ID" | tee -a $containers_file
        echo "dind$UNIQUE_ID$i" | tee -a $container_names_file 
      else
        echo -e "${RED}Failed to start container for ebesucher firefox restart..${NOCOLOUR}"
        exit 1
      fi
    fi
        
    # Create folder and copy files
    mkdir -p $PWD/$firefox_data_folder/data$i
    sudo chmod -R 777 $PWD/$firefox_profile_data
    cp -r $PWD/$firefox_profile_data/* $PWD/$firefox_data_folder/data$i/
    sudo chmod -R 777 $PWD/$firefox_data_folder/data$i
    if [[  ! $proxy ]]; then
      ebesucher_first_port=$(check_open_ports $ebesucher_first_port 1)
      if ! expr "$ebesucher_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $ebesucher_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Ebesucher. Resolve or disable Ebesucher to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      eb_port="-p $ebesucher_first_port:5800"
    fi
    if CONTAINER_ID=$(sudo docker run -d --name ebesucher$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM --restart=always -e FF_OPEN_URL="https://www.ebesucher.com/surfbar/$EBESUCHER_USERNAME" -e VNC_LISTENING_PORT=-1 -v $PWD/$firefox_data_folder/data$i:/config:rw $eb_port jlesage/firefox); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "ebesucher$UNIQUE_ID$i" | tee -a $container_names_file 
      echo "ebesucher$UNIQUE_ID$i" | tee -a $firefox_containers_file
      echo "http://127.0.0.1:$ebesucher_first_port" |tee -a $ebesucher_file
      ebesucher_first_port=`expr $ebesucher_first_port + 1`      
    else
      echo -e "${RED}Failed to start container for Ebesucher..${NOCOLOUR}"
    fi
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Ebesucher username is not configured. Ignoring Ebesucher..${NOCOLOUR}"
    fi
  fi

  # Starting Adnade container
  if [[ $ADNADE_USERNAME ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull jlesage/firefox
    fi
        
    if [[  ! $proxy ]]; then
      adnade_first_port=$(check_open_ports $adnade_first_port 1)
      if ! expr "$adnade_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $adnade_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Adnade. Resolve or disable Adnade to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      ad_port="-p $adnade_first_port:5800"
    fi

    if CONTAINER_ID=$(sudo docker run -d --name adnade$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM --restart=always -e FF_OPEN_URL="https://adnade.net/ptp/?user=$ADNADE_USERNAME" -e VNC_LISTENING_PORT=-1 $ad_port jlesage/firefox); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "adnade$UNIQUE_ID$i" | tee -a $container_names_file 
      echo "http://127.0.0.1:$adnade_first_port" | tee -a $adnade_file
      adnade_first_port=`expr $adnade_first_port + 1`      
    else
      echo -e "${RED}Failed to start container for Adnade..${NOCOLOUR}"
    fi
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Adnade username is not configured. Ignoring Adnade..${NOCOLOUR}"
    fi
  fi
  
  # Starting BitPing container
  if [ "$BITPING" = true ]; then
    echo -e "${GREEN}Starting Bitping container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull --platform=linux/amd64 bitping/bitping-node:latest  
    fi 
    if CONTAINER_ID=$(sudo docker run -d --name bitping$UNIQUE_ID$i --restart=always --platform=linux/amd64 $NETWORK_TUN $LOGS_PARAM --mount type=bind,source="$PWD/$bitping_folder/",target=/root/.bitping bitping/bitping-node:latest); then
      echo "$CONTAINER_ID" | tee -a $containers_file 
      echo "bitping$UNIQUE_ID$i" | tee -a $container_names_file 
    else
      echo -e "${RED}Failed to start container for BitPing..${NOCOLOUR}"
    fi
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}BitPing Node is not enabled. Ignoring BitPing..${NOCOLOUR}"
    fi
  fi

  # Starting Repocket container
  if [[ $REPOCKET_EMAIL && $REPOCKET_API ]]; then
    echo -e "${GREEN}Starting Repocket container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull repocket/repocket
    fi
    if CONTAINER_ID=$(sudo docker run -d --name repocket$UNIQUE_ID$i --restart=always $NETWORK_TUN $LOGS_PARAM -e RP_EMAIL=$REPOCKET_EMAIL -e RP_API_KEY=$REPOCKET_API repocket/repocket); then
      echo "$CONTAINER_ID" | tee -a $containers_file 
      echo "repocket$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for Repocket..${NOCOLOUR}"
    fi
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Repocket Email or Api is not configured. Ignoring Repocket..${NOCOLOUR}"
    fi
  fi

  # Starting Traffmonetizer container
  if [[ $TRAFFMONETIZER_TOKEN ]]; then
    echo -e "${GREEN}Starting Traffmonetizer container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull --platform=linux/amd64 traffmonetizer/cli_v2
    fi
    mkdir -p $PWD/$traffmonetizer_data_folder/data$i
    sudo chmod -R 777 $PWD/$traffmonetizer_data_folder/data$i
    traffmonetizer_volume="-v $PWD/$traffmonetizer_data_folder/data$i:/app/traffmonetizer"
    if CONTAINER_ID=$(sudo  docker run -d --name traffmon$UNIQUE_ID$i --platform=linux/amd64 --restart=always $LOGS_PARAM $NETWORK_TUN $traffmonetizer_volume traffmonetizer/cli_v2 start accept --device-name $DEVICE_NAME$i --token $TRAFFMONETIZER_TOKEN); then
      echo "$CONTAINER_ID" | tee -a $containers_file 
      echo "traffmon$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for Traffmonetizer..${NOCOLOUR}"
    fi
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Traffmonetizer Token is not configured. Ignoring Traffmonetizer..${NOCOLOUR}"
    fi
  fi

  # Starting ProxyRack container
  if [[ $PROXY_RACK_API ]]; then
    echo -e "${GREEN}Starting ProxyRack container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull --platform=linux/amd64 proxyrack/pop
    fi
    mkdir -p $PWD/$proxyrack_data_folder/data$i
    sudo chmod -R 777 $PWD/$proxyrack_data_folder
    proxyrack_volume=""
    proxyrack_uuid=""
    if [ -f $PWD/$proxyrack_data_folder/data$i/uuid.cfg ] && proxyrack_uuid=$(cat $PWD/$proxyrack_data_folder/data$i/uuid.cfg);then
      if [[ $proxyrack_uuid ]];then
       echo "UUID already exists"
       proxyrack_volume="-v $PWD/$proxyrack_data_folder/data$i/uuid.cfg:/app/uuid.cfg"
      else
        sudo rm $PWD/$proxyrack_data_folder/data$i/uuid.cfg
      fi
    fi

    if CONTAINER_ID=$(sudo docker run -d --name proxyrack$UNIQUE_ID$i --platform=linux/amd64 $NETWORK_TUN $LOGS_PARAM --restart=always $proxyrack_volume -e api_key=$PROXY_RACK_API -e device_name=$DEVICE_NAME$i proxyrack/pop); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "proxyrack$UNIQUE_ID$i" | tee -a $container_names_file
      if [[ ! -f $PWD/$proxyrack_data_folder/data$i/uuid.cfg ]];then
         sleep 5
         sudo docker exec $CONTAINER_ID cat uuid.cfg > $PWD/$proxyrack_data_folder/data$i/uuid.cfg
      fi
    else
      echo -e "${RED}Failed to start container for ProxyRack..${NOCOLOUR}"
    fi
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}ProxyRack Api is not configured. Ignoring ProxyRack..${NOCOLOUR}"
    fi
  fi


  # Starting IPRoyals pawns container
  if [[ $IPROYALS_EMAIL && $IPROYALS_PASSWORD ]]; then
    echo -e "${GREEN}Starting IPRoyals container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull iproyal/pawns-cli:latest
    fi
    if CONTAINER_ID=$(sudo docker run -d --name pawns$UNIQUE_ID$i --restart=always $LOGS_PARAM $NETWORK_TUN iproyal/pawns-cli:latest -email=$IPROYALS_EMAIL -password=$IPROYALS_PASSWORD -device-name=$DEVICE_NAME$i -device-id=$DEVICE_NAME$i -accept-tos); then
      echo "$CONTAINER_ID" | tee -a $containers_file 
      echo "pawns$UNIQUE_ID$i" | tee -a $container_names_file 
    else
      echo -e "${RED}Failed to start container for IPRoyals..${NOCOLOUR}"
    fi   
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}IPRoyals Email or Password is not configured. Ignoring IPRoyals..${NOCOLOUR}"
    fi
  fi
  
  # Starting Honeygain container
  if [[ $HONEYGAIN_EMAIL && $HONEYGAIN_PASSWORD ]]; then
    echo -e "${GREEN}Starting Honeygain container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull --platform=linux/amd64 honeygain/honeygain    
    fi
    if CONTAINER_ID=$(sudo docker run -d --name honey$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM --restart=always --platform=linux/amd64 honeygain/honeygain -tou-accept -email $HONEYGAIN_EMAIL -pass $HONEYGAIN_PASSWORD -device $DEVICE_NAME$i); then
      echo "$CONTAINER_ID" | tee -a $containers_file 
      echo "honey$UNIQUE_ID$i" | tee -a $container_names_file 
    else
      echo -e "${RED}Failed to start container for Honeygain..${NOCOLOUR}"
  fi
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Honeygain Email or Password is not configured. Ignoring Honeygain..${NOCOLOUR}"
    fi
  fi

  # Starting Peer2Profit container
  if [[ $PEER2PROFIT_EMAIL ]]; then
    echo -e "${GREEN}Starting Peer2Profit container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull peer2profit/peer2profit_linux:latest     
    fi
    if CONTAINER_ID=$(sudo docker run -d --name peer2profit$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM --restart always -e P2P_EMAIL=$PEER2PROFIT_EMAIL peer2profit/peer2profit_linux:latest); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "peer2profit$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for Peer2Profit..${NOCOLOUR}"
    fi   
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Peer2Profit Email is not configured. Ignoring Peer2Profit..${NOCOLOUR}"
    fi
  fi

  # Starting PacketStream container
  if [[ $PACKETSTREAM_CID ]]; then
    echo -e "${GREEN}Starting PacketStream container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull packetstream/psclient:latest     
    fi    
    if CONTAINER_ID=$(sudo docker run -d --name packetstream$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM --restart always -e CID=$PACKETSTREAM_CID packetstream/psclient:latest); then
      echo "$CONTAINER_ID" | tee -a $containers_file 
      echo "packetstream$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for PacketStream..${NOCOLOUR}"
    fi   
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}PacketStream CID is not configured. Ignoring PacketStream..${NOCOLOUR}"
    fi
  fi

  # Starting Proxylite container
  if [[ $PROXYLITE_USER_ID ]]; then
    echo -e "${GREEN}Starting Proxylite container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull proxylite/proxyservice     
    fi
    if CONTAINER_ID=$(sudo docker run -d --name proxylite$UNIQUE_ID$i --platform=linux/amd64 $NETWORK_TUN $LOGS_PARAM  -e USER_ID=$PROXYLITE_USER_ID --restart=always proxylite/proxyservice); then
      echo "$CONTAINER_ID" | tee -a $containers_file 
      echo "proxylite$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for Proxylite..${NOCOLOUR}"
    fi 
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Proxylite is not configured. Ignoring Proxylite..${NOCOLOUR}"
    fi
  fi

  # Starting Earnapp container
  if [ "$EARNAPP" = true ]; then
    echo -e "${GREEN}Starting Earnapp container..${NOCOLOUR}"
    echo -e "${GREEN}Copy the following node url and paste in your earnapp dashboard${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $earnapp_file in the same folder${NOCOLOUR}"
    RANDOM=$(date +%s)
    RANDOM_ID="$(echo -n "$RANDOM" | md5sum | cut -c1-32)"
    date_time=`date "+%D %T"`
    if [ "$container_pulled" = false ]; then
      sudo docker pull --platform=linux/amd64 fazalfarhan01/earnapp:lite
    fi
    mkdir -p $PWD/$earnapp_data_folder/data$i
    sudo chmod -R 777 $PWD/$earnapp_data_folder/data$i
    if [ -f $earnapp_file ] && uuid=$(sed "${i}q;d" $earnapp_file | grep -o 'https[^[:space:]]*'| sed 's/https:\/\/earnapp.com\/r\///g');then
      if [[ $uuid ]];then
        echo $uuid
      else
        echo "UUID does not exist, creating UUID"
        uuid=sdk-node-$RANDOM_ID
        printf "$date_time https://earnapp.com/r/%s\n" "$uuid" | tee -a $earnapp_file
      fi
    else
      echo "UUID does not exist, creating UUID"
      uuid=sdk-node-$RANDOM_ID
      printf "$date_time https://earnapp.com/r/%s\n" "$uuid" | tee -a $earnapp_file
    fi
    
    if CONTAINER_ID=$(sudo docker run -d --name earnapp$UNIQUE_ID$i --platform=linux/amd64 $LOGS_PARAM --restart=always $NETWORK_TUN -v $PWD/$earnapp_data_folder/data$i:/etc/earnapp -e EARNAPP_UUID=$uuid fazalfarhan01/earnapp:lite); then
      echo "$CONTAINER_ID" | tee -a $containers_file 
      echo "earnapp$UNIQUE_ID$i" | tee -a $container_names_file 
    else
      echo -e "${RED}Failed to start container for Earnapp..${NOCOLOUR}"
    fi  
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Earnapp is not enabled. Ignoring Earnapp..${NOCOLOUR}"
    fi
  fi
  
  container_pulled=true
} 

if [[ "$1" == "--start" ]]; then
  echo -e "\n\nStarting.."
  
  # Check if the required files are present
  for required_file in "${required_files[@]}"
  do
  if [ ! -f "$required_file" ]; then
    echo -e "${RED}Required file $required_file does not exist, exiting..${NOCOLOUR}"
    exit 1
  fi
  done
   
   
  for file in "${files_to_be_removed[@]}"
  do
  if [ -f "$file" ]; then
    echo -e "${RED}File $file still exists, there might be containers still running. Please stop them and delete before running the script. Exiting..${NOCOLOUR}"
    echo -e "To stop and delete containers run the following command\n"
    echo -e "${YELLOW}sudo bash internetIncome.sh --delete${NOCOLOUR}\n"
    exit 1
  fi
  done
  
  for folder in "${folders_to_be_removed[@]}"
  do
  if [ -d "$folder" ]; then
    echo -e "${RED}Folder $folder still exists, there might be containers still running. Please stop them and delete before running the script. Exiting..${NOCOLOUR}"
    echo -e "To stop and delete containers run the following command\n"
    echo -e "${YELLOW}sudo bash internetIncome.sh --delete${NOCOLOUR}\n"
    exit 1
  fi
  done

  # Remove special characters ^M from properties file
  sed -i 's/\r//g' $properties_file
  
  # Read the properties file and export variables to the current shell
  while IFS= read -r line; do
    # Ignore lines that start with #
    if [[ $line != '#'* ]]; then
        # Split the line at the first occurrence of =
        key="${line%%=*}"
        value="${line#*=}"
        # Trim leading and trailing whitespace from key and value
        key="${key%"${key##*[![:space:]]}"}"
        value="${value%"${value##*[![:space:]]}"}"
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
    echo -e "${GREEN}USE_PROXIES is enabled, using proxies..${NOCOLOUR}" 
    if [ ! -f "$proxies_file" ]; then
      echo -e "${RED}Proxies file $proxies_file does not exist, exiting..${NOCOLOUR}"
      exit 1
    fi

    # Remove special characters ^M from proxies file
    sed -i 's/\r//g' $proxies_file
    
    i=0;
    while IFS= read -r line || [ -n "$line" ]; do
      if [[ "$line" =~ ^[^#].* ]]; then
        i=`expr $i + 1`
        start_containers "$i" "$line"
      fi
    done < $proxies_file
  else
    echo -e "${RED}USE_PROXIES is disabled, using direct internet connection..${NOCOLOUR}" 
    start_containers 
  fi
fi

if [[ "$1" == "--delete" ]]; then
  echo -e "\n\nDeleting Containers and networks.."
  
  # Delete containers by container names
  if [ -f "$container_names_file" ]; then
    for i in `cat $container_names_file`
    do 
      # Check if container exists
      if sudo docker inspect $i >/dev/null 2>&1; then
        # Stop and Remove container
        sudo docker rm -f $i
      else
        echo "Container $i does not exist"
      fi
    done
    # Delete the container file
    rm $container_names_file
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
  
  for file in "${files_to_be_removed[@]}"
  do
  if [ -f "$file" ]; then
    rm $file
  fi
  done
  
  for folder in "${folders_to_be_removed[@]}"
  do
  if [ -d "$folder" ]; then
    rm -Rf $folder;
  fi
  done

fi

if [[ "$1" == "--deleteBackup" ]]; then
  echo -e "\n\nDeleting backup folders and files.."

  for file in "${files_to_be_removed[@]}"
  do
  if [ -f "$file" ]; then
    echo -e "${RED}File $file still exists, there might be containers still running. Please stop them and delete before running the script. Exiting..${NOCOLOUR}"
    echo -e "To stop and delete containers run the following command\n"
    echo -e "${YELLOW}sudo bash internetIncome.sh --delete${NOCOLOUR}\n"
    exit 1
  fi
  done
  
  for folder in "${folders_to_be_removed[@]}"
  do
  if [ -d "$folder" ]; then
    echo -e "${RED}Folder $folder still exists, there might be containers still running. Please stop them and delete before running the script. Exiting..${NOCOLOUR}"
    echo -e "To stop and delete containers run the following command\n"
    echo -e "${YELLOW}sudo bash internetIncome.sh --delete${NOCOLOUR}\n"
    exit 1
  fi
  done
    
  for file in "${back_up_files[@]}"
  do
  if [ -f "$file" ]; then
    rm $file
  fi
  done
  
  for folder in "${back_up_folders[@]}"
  do
  if [ -d "$folder" ]; then
    rm -Rf $folder;
  fi
  done

fi


if [[ ! "$1" ]]; then
  echo "No option provided. Use --start or --delete to execute"
fi
