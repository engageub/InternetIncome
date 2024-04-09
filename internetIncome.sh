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
vpns_file="vpns.txt"
multi_ip_file="multiips.txt"
containers_file="containers.txt"
container_names_file="containernames.txt"
earnapp_file="earnapp.txt"
earnapp_data_folder="earnappdata"
networks_file="networks.txt"
mysterium_file="mysterium.txt"
mysterium_data_folder="mysterium-data"
ebesucher_file="ebesucher.txt"
custom_chrome_file="custom_chrome.txt"
custom_chrome_data_folder="custom-chrome-data"
custom_firefox_file="custom_firefox.txt"
custom_firefox_data_folder="custom-firefox-data"
adnade_file="adnade.txt"
firefox_containers_file="firefoxcontainers.txt"
chrome_containers_file="chromecontainers.txt"
adnade_containers_file="adnadecontainers.txt"
bitping_data_folder="bitping-data"
firefox_data_folder="firefoxdata"
firefox_profile_data="firefoxprofiledata"
firefox_profile_zipfile="firefoxprofiledata.zip"
restart_file="restart.sh"
generate_device_ids_file="generateDeviceIds.sh"
chrome_data_folder="chromedata"
adnade_data_folder="adnadedata"
chrome_profile_data="chromeprofiledata"
chrome_profile_zipfile="chromeprofiledata.zip"
traffmonetizer_data_folder="traffmonetizerdata"
proxyrack_file="proxyrack.txt"
cloud_collab_file="cloudcollab.txt"
required_files=($banner_file $properties_file $firefox_profile_zipfile $restart_file $generate_device_ids_file)
files_to_be_removed=($containers_file $container_names_file $cloud_collab_file $networks_file $mysterium_file $ebesucher_file $adnade_file $firefox_containers_file $chrome_containers_file $adnade_containers_file $custom_chrome_file $custom_firefox_file)
folders_to_be_removed=($bitping_data_folder $firefox_data_folder $firefox_profile_data $adnade_data_folder $chrome_data_folder $chrome_profile_data $earnapp_data_folder)
back_up_folders=($traffmonetizer_data_folder $mysterium_data_folder $custom_chrome_data_folder $custom_firefox_data_folder)
back_up_files=($proxyrack_file $earnapp_file)
restricted_ports=(1 7 9 11 13 15 17 19 20 21 22 23 25 37 42 43 53 69 77 79 87 95 101 102 103 104 109 110 111 113 115 117 119 123 135 137 139 143 161 179 389 427 465 512 513 514 515 526 530 531 532 540 548 554 556 563 587 601 636 993 995 1719 1720 1723 2049 3659 4045 5060 5061 6000 6566 6665 6666 6667 6668 6669 6697 10080)
container_pulled=false

# Mysterium and ebesucher first port
mysterium_first_port=2000
ebesucher_first_port=3000
adnade_first_port=4000
meson_first_port=9000
custom_firefox_first_port=5000
custom_chrome_first_port=7000

#Unique Id
UNIQUE_ID=`cat /dev/urandom | LC_ALL=C tr -dc 'a-f0-9' | dd bs=1 count=32 2>/dev/null`

# Use banner if exists
if [ -f "$banner_file" ]; then
  for _ in {1..3}; do
    for color in "${RED}" "${GREEN}" "${YELLOW}"; do
      clear
      echo -e "$color"
      cat "$banner_file"
      sleep 0.5
    done
  done
  echo -e "${NOCOLOUR}"
fi

# Generate device Ids
generate_device_ids() {
  if [ "$CLOUDCOLLAB" = true ]; then
    echo "Waiting 30 seconds before generating device Ids"
    sleep 30
    sudo bash $generate_device_ids_file
  fi
}

# Check for open ports
check_open_ports() {
  local first_port=$1
  
  # Check if current Port is open
  port_is_open() {
    local port_to_check=$1
    { timeout 1 bash -c "echo > /dev/tcp/localhost/$port_to_check" > /dev/null; } 2>/dev/null
  }

  # Find the next available port
  while true; do
    if [[ ! " ${restricted_ports[@]} " =~ " $first_port " ]]; then
      if port_is_open "$first_port"; then
        first_port=$((first_port+1))
      else
        break
      fi
    else
      first_port=$((first_port+1))
    fi
  done

  echo $first_port
}

# Execute docker command
execute_docker_command() {
  # Store parameters as an array
  container_parameters=("$@")
  app_name=${container_parameters[0]}
  container_name=${container_parameters[1]}
  echo -e "${GREEN}Starting $app_name container..${NOCOLOUR}"
  if CONTAINER_ID=$(sudo docker run -d --name $container_name --restart=always "${container_parameters[@]:2}"); then
    echo "$container_name" | tee -a $container_names_file
    echo "$CONTAINER_ID" | tee -a $containers_file
  else
    echo -e "${RED}Failed to start container for $app_name..Exiting..${NOCOLOUR}"
    exit 1
  fi
  # Delay between each container start
  if [[ $DELAY_BETWEEN_CONTAINER =~ ^[0-9]+$ ]]; then
    sleep $DELAY_BETWEEN_CONTAINER
  fi
}

# Start all containers 
start_containers() {

  i=$1
  proxy=$2
  vpn_enabled=$3

  if [[ "$ENABLE_LOGS" = false ]]; then
    LOGS_PARAM="--log-driver none"
    TUN_LOG_PARAM="silent"
  else
    TUN_LOG_PARAM="info"
  fi
  
  if [[ $MAX_MEMORY ]]; then
    MAX_MEMORY_PARAM="-m $MAX_MEMORY"
  fi
  
  if [[ $MEMORY_RESERVATION ]]; then
    MEMORY_RESERVATION_PARAM="--memory-reservation=$MEMORY_RESERVATION"
  fi
  
  if [[ $CPU ]]; then
    CPU_PARAM="--cpus=$CPU"
  fi

  if [[ $i && $proxy ]]; then
    NETWORK_TUN="--network=container:tun$UNIQUE_ID$i"
        
    if [ "$MYSTERIUM" = true ]; then
      mysterium_first_port=$(check_open_ports $mysterium_first_port)
      if ! expr "$mysterium_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $mysterium_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Mysterium node. Resolve or disable Mysterium to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      mysterium_port="-p $mysterium_first_port:4449 "
    fi
    
    if [[ $EBESUCHER_USERNAME ]]; then
      ebesucher_first_port=$(check_open_ports $ebesucher_first_port)
      if ! expr "$ebesucher_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $ebesucher_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Ebesucher. Resolve or disable Ebesucher to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      if [ "$EBESUCHER_USE_CHROME" = true ]; then
          ebesucher_port="-p $ebesucher_first_port:3000 "
      else
          ebesucher_port="-p $ebesucher_first_port:5800 "
      fi
    fi

    if [[ $ADNADE_USERNAME ]]; then
      adnade_first_port=$(check_open_ports $adnade_first_port)
      if ! expr "$adnade_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $adnade_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Adnade. Resolve or disable Adnade to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      if [ "$ADNADE_USE_CHROME" = true ]; then
          adnade_port="-p $adnade_first_port:3500 "
      else
          adnade_port="-p $adnade_first_port:5900 "
      fi 
    fi

    if [ "$CUSTOM_FIREFOX" = true ];then
      custom_firefox_first_port=$(check_open_ports $custom_firefox_first_port)
      if ! expr "$custom_firefox_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $custom_firefox_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Custom Firefox. Resolve or disable Custom Firefox to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      custom_firefox_port="-p $custom_firefox_first_port:5911 "
    fi

    if [ "$CUSTOM_CHROME" = true ];then
      custom_chrome_first_port=$(check_open_ports $custom_chrome_first_port)
      if ! expr "$custom_chrome_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $custom_chrome_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Custom Chrome. Resolve or disable Custom Chrome to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      custom_chrome_port="-p $custom_chrome_first_port:3200 "
    fi
    
    combined_ports=$mysterium_port$ebesucher_port$adnade_port$custom_firefox_port$custom_chrome_port
  
    if [ "$vpn_enabled" = true ];then
      # Starting vpn containers
      if [ "$container_pulled" = false ]; then
        sudo docker pull ghcr.io/qdm12/gluetun
      fi
      NETWORK_TUN="--network=container:gluetun$UNIQUE_ID$i"
      docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM  $proxy -v '/dev/net/tun:/dev/net/tun' --cap-add=NET_ADMIN $combined_ports ghcr.io/qdm12/gluetun)
      execute_docker_command "VPN" "gluetun$UNIQUE_ID$i" "${docker_parameters[@]}"
    elif [ "$vpn_enabled" = false ];then
      subnet_number=`expr 32 + $i`
      NETWORK_TUN="--network multi$UNIQUE_ID$i"
      if NETWORK_ID=$(sudo docker network create multi$UNIQUE_ID$i --driver bridge --subnet 192.168.$subnet_number.0/24); then
        echo "multi$UNIQUE_ID$i" | tee -a $networks_file
        sudo iptables -t nat -I POSTROUTING -s 192.168.$subnet_number.0/24 -j SNAT --to-source $proxy
      else
        echo -e "${RED}Failed to create network multi$UNIQUE_ID$i..Exiting..${NOCOLOUR}" 
        exit 1
      fi
    else 
      # Starting tun containers
      if [ "$container_pulled" = false ]; then
        sudo docker pull xjasonlyu/tun2socks:v2.5.2
      fi
      if [ "$USE_SOCKS5_DNS" = true ]; then
        EXTRA_COMMANDS='echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf;'
      elif [ "$USE_DNS_OVER_HTTPS" = true ]; then
        EXTRA_COMMANDS='echo -e "options use-vc\nnameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf;ip rule add iif lo ipproto udp dport 53 lookup main;'
      else
        EXTRA_COMMANDS='echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf;ip rule add iif lo ipproto udp dport 53 lookup main;'
      fi
      if [ "$USE_CUSTOM_NETWORK" = true ] && { [ "$i" -eq 1 ] || [ "$((i % 1000))" -eq 0 ]; }; then
        echo -e "${GREEN}Creating new network..${NOCOLOUR}"
        network_name="net$UNIQUE_ID$i"
        CUSTOM_NETWORK="--network $network_name"
        if NETWORK_ID=$(sudo docker network create $network_name); then
          echo "$network_name" | tee -a $networks_file
        else
          echo -e "${RED}Failed to create network $network_name..Exiting..${NOCOLOUR}" 
          exit 1
        fi
      fi
      docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $CUSTOM_NETWORK -e LOGLEVEL=$TUN_LOG_PARAM -e PROXY=$proxy -e EXTRA_COMMANDS="$EXTRA_COMMANDS" -v '/dev/net/tun:/dev/net/tun' --cap-add=NET_ADMIN $combined_ports xjasonlyu/tun2socks:v2.5.2)
      execute_docker_command "Proxy" "tun$UNIQUE_ID$i" "${docker_parameters[@]}"
    fi
  fi
  
  # Starting Mysterium container
  if [ "$MYSTERIUM" = true ]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull mysteriumnetwork/myst:latest  
    fi
    if [[ ! $proxy ]] || [ "$vpn_enabled" = false ]; then
      mysterium_first_port=$(check_open_ports $mysterium_first_port)
      if ! expr "$mysterium_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $mysterium_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Mysterium node. Resolve or disable Mysterium to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      myst_port="-p $mysterium_first_port:4449"
    fi
    mkdir -p $PWD/$mysterium_data_folder/node$i
    sudo chmod -R 777 $PWD/$mysterium_data_folder/node$i
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM --cap-add=NET_ADMIN $NETWORK_TUN -v $PWD/$mysterium_data_folder/node$i:/var/lib/mysterium-node $myst_port mysteriumnetwork/myst:latest service --agreed-terms-and-conditions)
    execute_docker_command "Mysterium" "myst$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the following node url and paste in your browser${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $mysterium_file in the same folder${NOCOLOUR}"
    echo "http://127.0.0.1:$mysterium_first_port" |tee -a $mysterium_file
    mysterium_first_port=`expr $mysterium_first_port + 1`
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Mysterium Node is not enabled. Ignoring Mysterium..${NOCOLOUR}"
    fi
  fi

  # Starting Custom Firefox container
  if [[ "$CUSTOM_FIREFOX" = true  ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull jlesage/firefox
    fi  
     
    if [[ ! $proxy ]] || [ "$vpn_enabled" = false ]; then
      custom_firefox_first_port=$(check_open_ports $custom_firefox_first_port)
      if ! expr "$custom_firefox_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $custom_firefox_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Custom Firefox. Resolve or disable Custom Firefox to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      cf_port="-p $custom_firefox_first_port:5911"
    fi
    
    mkdir -p $PWD/$custom_firefox_data_folder/data$i
    sudo chmod -R 777 $PWD/$custom_firefox_data_folder/data$i
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN -e KEEP_APP_RUNNING=1 -e VNC_LISTENING_PORT=-1 -e WEB_LISTENING_PORT=5911 $cf_port -v $PWD/$custom_firefox_data_folder/data$i:/config:rw jlesage/firefox)
    execute_docker_command "Custom Firefox" "customfirefox$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the following node url and paste in your browser if required..${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $custom_firefox_file in the same folder${NOCOLOUR}"
    echo "http://127.0.0.1:$custom_firefox_first_port" |tee -a $custom_firefox_file
    custom_firefox_first_port=`expr $custom_firefox_first_port + 1`
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Custom firefox is not configured. Ignoring Custom Firefox..${NOCOLOUR}"
    fi
  fi

  # Starting Custom Chrome container
  if [[ "$CUSTOM_CHROME" = true ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull lscr.io/linuxserver/chromium:latest
    fi
         
    if [[ ! $proxy ]] || [ "$vpn_enabled" = false ]; then
      custom_chrome_first_port=$(check_open_ports $custom_chrome_first_port)
      if ! expr "$custom_chrome_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $custom_chrome_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Custom Chrome. Resolve or disable Custom Chrome to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      cc_port="-p $custom_chrome_first_port:3200 "
    fi
    
    mkdir -p $PWD/$custom_chrome_data_folder/data$i
    sudo chown -R 911:911 $PWD/$custom_chrome_data_folder/data$i    
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN --security-opt seccomp=unconfined -e TZ=Etc/UTC   -e CUSTOM_HTTPS_PORT=3201 -e CUSTOM_PORT=3200 --shm-size="1gb" $cc_port -v $PWD/$custom_chrome_data_folder/data$i:/config lscr.io/linuxserver/chromium:latest)
    execute_docker_command "Custom Chrome" "customchrome$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the following node url and paste in your browser if required..${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $custom_chrome_file in the same folder${NOCOLOUR}"
    echo "http://127.0.0.1:$custom_chrome_first_port" |tee -a $custom_chrome_file
    custom_chrome_first_port=`expr $custom_chrome_first_port + 1`
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Custom chrome is not configured. Ignoring Custom Chrome..${NOCOLOUR}"
    fi
  fi
  
  # Starting Ebesucher Firefox container
  if [[ $EBESUCHER_USERNAME && "$EBESUCHER_USE_CHROME" = false  ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull jlesage/firefox
      
      # Exit, if firefox profile zip file is missing
      if [ ! -f "$PWD/$firefox_profile_zipfile" ];then
        echo -e "${RED}Firefox profile file does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi
      
      # Unzip the file
      unzip -o $firefox_profile_zipfile
      
      # Exit, if firefox profile data is missing
      if [ ! -d "$PWD/$firefox_profile_data" ];then
        echo -e "${RED}Firefox Data folder does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi
      
      docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/usr/bin/docker -v $PWD:/firefox docker:18.06.2-dind /bin/sh -c 'apk add --no-cache bash && cd /firefox && chmod +x /firefox/restart.sh && while true; do sleep 3600; /firefox/restart.sh --restartFirefox; done')
      execute_docker_command "Firefox Restart" "dind$UNIQUE_ID$i" "${docker_parameters[@]}"
    fi
        
    # Create folder and copy files
    mkdir -p $PWD/$firefox_data_folder/data$i
    sudo chmod -R 777 $PWD/$firefox_profile_data
    cp -r $PWD/$firefox_profile_data/* $PWD/$firefox_data_folder/data$i/
    sudo chmod -R 777 $PWD/$firefox_data_folder/data$i
    if [[ ! $proxy ]] || [ "$vpn_enabled" = false ]; then
      ebesucher_first_port=$(check_open_ports $ebesucher_first_port)
      if ! expr "$ebesucher_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $ebesucher_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Ebesucher. Resolve or disable Ebesucher to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      eb_port="-p $ebesucher_first_port:5800"
    fi

    # Setting random window height and width for firefox
    if [ "$EBESUCHER_USE_RANDOM_DISPLAY" = true ]; then
      MIN_WIDTH=1280
      MIN_HEIGHT=1024
      WINDOW_WIDTH=$((RANDOM % (1920 - MIN_WIDTH + 1) + MIN_WIDTH))
      WINDOW_HEIGHT=$((RANDOM % (1080 - MIN_HEIGHT + 1) + MIN_HEIGHT))
      DISPLAY_PARAMETERS="-e DISPLAY_WIDTH=$WINDOW_WIDTH  -e DISPLAY_HEIGHT=$WINDOW_HEIGHT"
    fi
    
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN -e KEEP_APP_RUNNING=1 -e FF_OPEN_URL="https://www.ebesucher.com/surfbar/$EBESUCHER_USERNAME" $DISPLAY_PARAMETERS -e VNC_LISTENING_PORT=-1 -v $PWD/$firefox_data_folder/data$i:/config:rw $eb_port jlesage/firefox)
    execute_docker_command "Ebesucher" "ebesucher$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the following node url and paste in your browser if required..${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $ebesucher_file in the same folder${NOCOLOUR}"
    echo "http://127.0.0.1:$ebesucher_first_port" |tee -a $ebesucher_file
    echo "ebesucher$UNIQUE_ID$i" | tee -a $firefox_containers_file
    ebesucher_first_port=`expr $ebesucher_first_port + 1`
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Ebesucher username for firefox is not configured. Ignoring Ebesucher..${NOCOLOUR}"
    fi
  fi

# Starting Ebesucher Chrome container
  if [[ $EBESUCHER_USERNAME && "$EBESUCHER_USE_CHROME" = true ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull lscr.io/linuxserver/chromium:latest

      # Download the chrome profile if not present
      if [ ! -f "$PWD/$chrome_profile_zipfile" ];then
        wget https://github.com/engageub/InternetIncome/releases/download/chromeprofiledata/chromeprofiledata.zip     
      fi
      
      # Exit, if chrome profile zip file is missing
      if [ ! -f "$PWD/$chrome_profile_zipfile" ];then
        echo -e "${RED}Chrome profile file does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi
      
      # Unzip the file
      unzip -o $chrome_profile_zipfile
      
      # Exit, if chrome profile data is missing
      if [ ! -d "$PWD/$chrome_profile_data" ];then
        echo -e "${RED}Chrome Data folder does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi
      
      docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/usr/bin/docker -v $PWD:/chrome docker:18.06.2-dind /bin/sh -c 'apk add --no-cache bash && cd /chrome && chmod +x /chrome/restart.sh && while true; do sleep 3600; /chrome/restart.sh --restartChrome; done')
      execute_docker_command "Chrome Restart" "dind$UNIQUE_ID$i" "${docker_parameters[@]}"
    fi
        
    # Create folder and copy files
    mkdir -p $PWD/$chrome_data_folder/data$i
    sudo chown -R 911:911 $PWD/$chrome_profile_data
    sudo cp -r $PWD/$chrome_profile_data $PWD/$chrome_data_folder/data$i
    sudo chown -R 911:911 $PWD/$chrome_data_folder/data$i
    
    if [[ ! $proxy ]] || [ "$vpn_enabled" = false ]; then
      ebesucher_first_port=$(check_open_ports $ebesucher_first_port)
      if ! expr "$ebesucher_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $ebesucher_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Ebesucher. Resolve or disable Ebesucher to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      eb_port="-p $ebesucher_first_port:3000 "
    fi
    
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN --security-opt seccomp=unconfined -e TZ=Etc/UTC -e CHROME_CLI="https://www.ebesucher.com/surfbar/$EBESUCHER_USERNAME" -v $PWD/$chrome_data_folder/data$i/$chrome_profile_data:/config --shm-size="1gb" $eb_port lscr.io/linuxserver/chromium:latest)
    execute_docker_command "Ebesucher" "ebesucher$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the following node url and paste in your browser if required..${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $ebesucher_file in the same folder${NOCOLOUR}"
    echo "http://127.0.0.1:$ebesucher_first_port" |tee -a $ebesucher_file
    echo "ebesucher$UNIQUE_ID$i" | tee -a $chrome_containers_file
    ebesucher_first_port=`expr $ebesucher_first_port + 1`
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Ebesucher username for chrome is not configured. Ignoring Ebesucher..${NOCOLOUR}"
    fi
  fi

  # Starting Adnade Firefox container
  if [[ $ADNADE_USERNAME && "$ADNADE_USE_CHROME" = false  ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull jlesage/firefox
      
      # Exit, if firefox profile zip file is missing
      if [ ! -f "$PWD/$firefox_profile_zipfile" ];then
        echo -e "${RED}Firefox profile file does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi
      
      # Unzip the file
      unzip -o $firefox_profile_zipfile
      
      # Exit, if firefox profile data is missing
      if [ ! -d "$PWD/$firefox_profile_data" ];then
        echo -e "${RED}Firefox Data folder does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi
      
      docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/usr/bin/docker -v $PWD:/firefox docker:18.06.2-dind /bin/sh -c 'apk add --no-cache bash && cd /firefox && chmod +x /firefox/restart.sh && while true; do sleep 7200; /firefox/restart.sh --restartAdnadeFirefox; done')
      execute_docker_command "Adnade Firefox Restart" "adnadedind$UNIQUE_ID$i" "${docker_parameters[@]}"
    fi
        
    # Create folder and copy files
    mkdir -p $PWD/$adnade_data_folder/data$i
    sudo chmod -R 777 $PWD/$firefox_profile_data
    cp -r $PWD/$firefox_profile_data/* $PWD/$adnade_data_folder/data$i/
    sudo chmod -R 777 $PWD/$adnade_data_folder/data$i
    if [[ ! $proxy ]] || [ "$vpn_enabled" = false ]; then
      adnade_first_port=$(check_open_ports $adnade_first_port)
      if ! expr "$adnade_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $adnade_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Adnade Firefox. Resolve or disable Adnade to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      ad_port="-p $adnade_first_port:5900"
    fi
    
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN -e FF_OPEN_URL="https://adnade.net/view.php?user=$ADNADE_USERNAME&multi=4" -e VNC_LISTENING_PORT=-1 -e WEB_LISTENING_PORT=5900 -v $PWD/$adnade_data_folder/data$i:/config:rw $ad_port jlesage/firefox)
    execute_docker_command "Adnade" "adnade$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the following node url and paste in your browser if required..${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $adnade_file in the same folder${NOCOLOUR}"
    echo "http://127.0.0.1:$adnade_first_port" |tee -a $adnade_file
    echo "adnade$UNIQUE_ID$i" | tee -a $adnade_containers_file
    adnade_first_port=`expr $adnade_first_port + 1`
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Adnade username for firefox is not configured. Ignoring Adnade..${NOCOLOUR}"
    fi
  fi
  
  # Starting Adnade Chrome container
  if [[ $ADNADE_USERNAME && "$ADNADE_USE_CHROME" = true ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull lscr.io/linuxserver/chromium:latest

      # Download the chrome profile if not present
      if [ ! -f "$PWD/$chrome_profile_zipfile" ];then
        wget https://github.com/engageub/InternetIncome/releases/download/chromeprofiledata/chromeprofiledata.zip     
      fi
      
      # Exit, if chrome profile zip file is missing
      if [ ! -f "$PWD/$chrome_profile_zipfile" ];then
        echo -e "${RED}Chrome profile file does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi
      
      # Unzip the file
      unzip -o $chrome_profile_zipfile
      
      # Exit, if chrome profile data is missing
      if [ ! -d "$PWD/$chrome_profile_data" ];then
        echo -e "${RED}Chrome Data folder does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi

      docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/usr/bin/docker -v $PWD:/chrome docker:18.06.2-dind /bin/sh -c 'apk add --no-cache bash && cd /chrome && chmod +x /chrome/restart.sh && while true; do sleep 7200; /chrome/restart.sh --restartAdnade; done')
      execute_docker_command "Adnade Restart" "dindAdnade$UNIQUE_ID$i" "${docker_parameters[@]}"
      
    fi
        
    # Create folder and copy files
    mkdir -p $PWD/$adnade_data_folder/data$i
    sudo chown -R 911:911 $PWD/$chrome_profile_data
    sudo cp -r $PWD/$chrome_profile_data $PWD/$adnade_data_folder/data$i
    sudo chown -R 911:911 $PWD/$adnade_data_folder/data$i
    
    if [[ ! $proxy ]] || [ "$vpn_enabled" = false ]; then
      adnade_first_port=$(check_open_ports $adnade_first_port)
      if ! expr "$adnade_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $adnade_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Adnade. Resolve or disable Adnade to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      ad_port="-p $adnade_first_port:3500 "
    fi
    
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN --security-opt seccomp=unconfined -e TZ=Etc/UTC -e CUSTOM_HTTPS_PORT=3501 -e CUSTOM_PORT=3500 -e CHROME_CLI="https://adnade.net/view.php?user=$ADNADE_USERNAME&multi=4" -v $PWD/$adnade_data_folder/data$i/$chrome_profile_data:/config --shm-size="1gb" $ad_port lscr.io/linuxserver/chromium:latest)
    execute_docker_command "Adnade" "adnade$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the following node url and paste in your browser if required..${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $adnade_file in the same folder${NOCOLOUR}"
    echo "http://127.0.0.1:$adnade_first_port" |tee -a $adnade_file
    echo "adnade$UNIQUE_ID$i" | tee -a $adnade_containers_file
    adnade_first_port=`expr $adnade_first_port + 1`
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Adnade username for chrome is not configured. Ignoring Adnade..${NOCOLOUR}"
    fi
  fi
  
  # Starting BitPing container
  if [[ $BITPING_EMAIL && $BITPING_PASSWORD ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull bitping/bitpingd:latest
    fi
    # Create bitping folder
    mkdir -p $PWD/$bitping_data_folder/data$i/.bitpingd
    sudo chmod -R 777 $PWD/$bitping_data_folder/data$i/.bitpingd
    sudo docker run --rm $NETWORK_TUN -v "$PWD/$bitping_data_folder/data$i/.bitpingd:/root/.bitpingd" --entrypoint /app/bitpingd bitping/bitpingd:latest login --email $BITPING_EMAIL --password $BITPING_PASSWORD
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN -v "$PWD/$bitping_data_folder/data$i/.bitpingd:/root/.bitpingd" bitping/bitpingd:latest)
    execute_docker_command "BitPing" "bitping$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}BitPing Node is not enabled. Ignoring BitPing..${NOCOLOUR}"
    fi
  fi

  # Starting Meson container
  if [[ $MESON_TOKEN ]]; then
    meson_first_port=$(check_open_ports $meson_first_port)
    if ! expr "$meson_first_port" : '[[:digit:]]*$' >/dev/null; then
      echo -e "${RED}Problem assigning port $meson_first_port ..${NOCOLOUR}"
      echo -e "${RED}Failed to start Meson. Resolve or disable Meson to continue. Exiting..${NOCOLOUR}"
      exit 1
    fi
    CPU_ARCH=`uname -m`
    container_image="--platform=linux/amd64 jepbura/meson"
    if [ "$CPU_ARCH" == "aarch64" ] || [ "$CPU_ARCH" == "arm64" ]; then
      container_image="jepbura/meson:arm64"
    fi
    if [ "$container_pulled" = false ]; then
      sudo docker pull $container_image
    fi
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN -p $meson_first_port:$meson_first_port -e PORT=$meson_first_port -e TOKEN=$MESON_TOKEN $container_image)
    execute_docker_command "Meson" "meson$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Meson Token is not configured. Ignoring Meson..${NOCOLOUR}"
    fi
  fi

  # Starting Repocket container
  if [[ $REPOCKET_EMAIL && $REPOCKET_API ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull repocket/repocket
    fi
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN -e RP_EMAIL=$REPOCKET_EMAIL -e RP_API_KEY=$REPOCKET_API repocket/repocket)
    execute_docker_command "Repocket" "repocket$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Repocket Email or Api is not configured. Ignoring Repocket..${NOCOLOUR}"
    fi
  fi

  # Starting Grass container
  if [[ $GRASS_USERNAME && $GRASS_PASSWORD ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull camislav/grass
    fi
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN -e GRASS_USER=$GRASS_USERNAME -e GRASS_PASS=$GRASS_PASSWORD -e ALLOW_DEBUG=False camislav/grass)
    execute_docker_command "Grass" "grass$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Grass Username or Password is not configured. Ignoring Grass..${NOCOLOUR}"
    fi
  fi

  # Starting Traffmonetizer container
  if [[ $TRAFFMONETIZER_TOKEN ]]; then
    CPU_ARCH=`uname -m`
    container_image="--platform=linux/amd64 traffmonetizer/cli_v2"
    if [ "$CPU_ARCH" == "aarch64" ] || [ "$CPU_ARCH" == "arm64" ]; then
      container_image="traffmonetizer/cli_v2:arm64v8"
    fi
    if [ "$container_pulled" = false ]; then
      sudo docker pull $container_image
    fi
    mkdir -p $PWD/$traffmonetizer_data_folder/data$i
    sudo chmod -R 777 $PWD/$traffmonetizer_data_folder/data$i
    traffmonetizer_volume="-v $PWD/$traffmonetizer_data_folder/data$i:/app/traffmonetizer"
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN $traffmonetizer_volume $container_image start accept --device-name $DEVICE_NAME$i --token $TRAFFMONETIZER_TOKEN)
    execute_docker_command "Traffmonetizer" "traffmon$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Traffmonetizer Token is not configured. Ignoring Traffmonetizer..${NOCOLOUR}"
    fi
  fi

  # Starting Earn Fm container
  if [[ $EARN_FM_API ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull earnfm/earnfm-client:latest
    fi
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN -e EARNFM_TOKEN=$EARN_FM_API earnfm/earnfm-client:latest)
    execute_docker_command "EarnFm" "earnfm$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}EarnFm Api is not configured. Ignoring EarnFm..${NOCOLOUR}"
    fi
  fi

  # Starting ProxyRack container
  if [ "$PROXYRACK" = true ]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull --platform=linux/amd64 proxyrack/pop
    fi
    sequence=$i
    if [ "$USE_DIRECT_CONNECTION" = true ]; then
      sequence=$((1 + i))
    fi
    if [ -f $proxyrack_file ] && proxyrack_uuid=$(sed "${sequence}q;d" $proxyrack_file);then
      if [[ $proxyrack_uuid ]];then
        echo $proxyrack_uuid
      else
        echo "Proxyrack UUID does not exist, creating UUID"
        proxyrack_uuid=`cat /dev/urandom | LC_ALL=C tr -dc 'A-F0-9' | dd bs=1 count=64 2>/dev/null`
        printf "%s\n" "$proxyrack_uuid" | tee -a $proxyrack_file
      fi
    else
      echo "Proxyrack UUID does not exist, creating UUID"
      proxyrack_uuid=`cat /dev/urandom | LC_ALL=C tr -dc 'A-F0-9' | dd bs=1 count=64 2>/dev/null`
      printf "%s\n" "$proxyrack_uuid" | tee -a $proxyrack_file
    fi
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM --platform=linux/amd64 $NETWORK_TUN -e UUID=$proxyrack_uuid proxyrack/pop)
    execute_docker_command "ProxyRack" "proxyrack$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the node uuid and paste in your proxyrack dashboard${NOCOLOUR}"
    echo -e "${GREEN}You will also find the uuids in the file $proxyrack_file in the same folder${NOCOLOUR}"
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}ProxyRack Api is not configured. Ignoring ProxyRack..${NOCOLOUR}"
    fi
  fi

  # Starting CloudCollab container
  if [ "$CLOUDCOLLAB" = true ]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull --platform=linux/amd64 cloudcollabapp/peer:x64
    fi
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM --platform=linux/amd64 $NETWORK_TUN cloudcollabapp/peer:x64)
    execute_docker_command "CloudCollab" "cloudcollab$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}You will find the device ids in the file $cloud_collab_file in the same folder${NOCOLOUR}"
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}CloudCollab is not enabled. Ignoring CloudCollab..${NOCOLOUR}"
    fi
  fi

  # Starting IPRoyals pawns container
  if [[ $IPROYALS_EMAIL && $IPROYALS_PASSWORD ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull iproyal/pawns-cli:latest
    fi
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN iproyal/pawns-cli:latest -email=$IPROYALS_EMAIL -password=$IPROYALS_PASSWORD -device-name=$DEVICE_NAME$i -device-id=$DEVICE_NAME$i -accept-tos)
    execute_docker_command "IPRoyals" "pawns$UNIQUE_ID$i" "${docker_parameters[@]}"  
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}IPRoyals Email or Password is not configured. Ignoring IPRoyals..${NOCOLOUR}"
    fi
  fi
  
  # Starting Honeygain container
  if [[ $HONEYGAIN_EMAIL && $HONEYGAIN_PASSWORD ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull honeygain/honeygain    
    fi
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN honeygain/honeygain -tou-accept -email $HONEYGAIN_EMAIL -pass $HONEYGAIN_PASSWORD -device $DEVICE_NAME$i)
    execute_docker_command "Honeygain" "honey$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Honeygain Email or Password is not configured. Ignoring Honeygain..${NOCOLOUR}"
    fi
  fi

  
  # Starting Gaganode container
  if [[ $GAGANODE_TOKEN ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull --platform=linux/amd64 jepbura/gaganode    
    fi
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN --platform=linux/amd64 -e TOKEN=$GAGANODE_TOKEN jepbura/gaganode)
    execute_docker_command "Gaganode" "gaganode$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Gaganode Token is not configured. Ignoring Gaganode..${NOCOLOUR}"
    fi
  fi

  # Starting Speedshare container
  if [[ $SPEEDSHARE_TOKEN ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull eldavo/speedshare    
    fi
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN -e CODE=$SPEEDSHARE_TOKEN eldavo/speedshare)
    execute_docker_command "Speedshare" "speedshare$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Speedshare Token is not configured. Ignoring Speedshare..${NOCOLOUR}"
    fi
  fi

  # Starting Peer2Profit container
  if [[ $PEER2PROFIT_EMAIL ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull --platform=linux/amd64 enwaiax/peer2profit   
    fi
    docker_parameters=(--platform=linux/amd64 $LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN -e email=$PEER2PROFIT_EMAIL enwaiax/peer2profit)
    execute_docker_command "Peer2Profit" "peer2profit$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Peer2Profit Email is not configured. Ignoring Peer2Profit..${NOCOLOUR}"
    fi
  fi

  # Starting PacketStream container
  if [[ $PACKETSTREAM_CID ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull packetstream/psclient:latest     
    fi
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN -e CID=$PACKETSTREAM_CID packetstream/psclient:latest)
    execute_docker_command "PacketStream" "packetstream$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}PacketStream CID is not configured. Ignoring PacketStream..${NOCOLOUR}"
    fi
  fi

  # Starting Proxylite container
  if [[ $PROXYLITE_USER_ID ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull proxylite/proxyservice     
    fi
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM --platform=linux/amd64 $NETWORK_TUN -e USER_ID=$PROXYLITE_USER_ID proxylite/proxyservice)
    execute_docker_command "Proxylite" "proxylite$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Proxylite is not configured. Ignoring Proxylite..${NOCOLOUR}"
    fi
  fi

  # Starting Earnapp container
  if [ "$EARNAPP" = true ]; then
    RANDOM_ID=`cat /dev/urandom | LC_ALL=C tr -dc 'a-f0-9' | dd bs=1 count=32 2>/dev/null`
    date_time=`date "+%D %T"`
    if [ "$container_pulled" = false ]; then
      sudo docker pull fazalfarhan01/earnapp:lite
    fi
    mkdir -p $PWD/$earnapp_data_folder/data$i
    sudo chmod -R 777 $PWD/$earnapp_data_folder/data$i
    sequence=$i
    if [ "$USE_DIRECT_CONNECTION" = true ]; then
      sequence=$((1 + i))
    fi
    if [ -f $earnapp_file ] && uuid=$(sed "${sequence}q;d" $earnapp_file | grep -o 'https[^[:space:]]*'| sed 's/https:\/\/earnapp.com\/r\///g');then
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
    docker_parameters=($LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $CPU_PARAM $NETWORK_TUN -v $PWD/$earnapp_data_folder/data$i:/etc/earnapp -e EARNAPP_UUID=$uuid fazalfarhan01/earnapp:lite)
    execute_docker_command "Earnapp" "earnapp$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the node url and paste in your earnapp dashboard${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $earnapp_file in the same folder${NOCOLOUR}"
  else
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Earnapp is not enabled. Ignoring Earnapp..${NOCOLOUR}"
    fi
  fi
  
  container_pulled=true
} 

if [[ "$1" == "--start" ]]; then
  echo -e "\n\nStarting.."
  STATUS=0;
  
  # Check if the required files are present
  for required_file in "${required_files[@]}"; do
    if [ ! -f "$required_file" ]; then
      echo -e "${RED}Required file $required_file does not exist, exiting..${NOCOLOUR}"
      exit 1
    fi
  done
   
  for file in "${files_to_be_removed[@]}"; do
    if [ -f "$file" ]; then
      echo -e "${RED}File $file still exists, there might be containers still running. Please stop them and delete before running the script. Exiting..${NOCOLOUR}"
      echo -e "To stop and delete containers run the following command\n"
      echo -e "${YELLOW}sudo bash internetIncome.sh --delete${NOCOLOUR}\n"
      exit 1
    fi
  done
  
  for folder in "${folders_to_be_removed[@]}"; do
    if [ -d "$folder" ]; then
      echo -e "${RED}Folder $folder still exists, there might be containers still running. Please stop them and delete before running the script. Exiting..${NOCOLOUR}"
      echo -e "To stop and delete containers run the following command\n"
      echo -e "${YELLOW}sudo bash internetIncome.sh --delete${NOCOLOUR}\n"
      exit 1
    fi
  done

  # Remove special character ^M from properties file
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

  # Use direct Connection
  if [ "$USE_DIRECT_CONNECTION" = true ]; then
     STATUS=1
     echo -e "${GREEN}USE_DIRECT_CONNECTION is enabled, using direct internet connection..${NOCOLOUR}" 
     start_containers
  fi

  # Use Vpns
  if [ "$USE_VPNS" = true ]; then
    STATUS=1
    echo -e "${GREEN}USE_VPNS is enabled, using vpns..${NOCOLOUR}" 
    if [ ! -f "$vpns_file" ]; then
      echo -e "${RED}Vpns file $vpns_file does not exist, exiting..${NOCOLOUR}"
      exit 1
    fi

    # Remove special character ^M from vpn file
    sed -i 's/\r//g' $vpns_file
    
    i=0;
    while IFS= read -r line || [ -n "$line" ]; do
      if [[ "$line" =~ ^[^#].* ]]; then
        i=`expr $i + 1`
        start_containers "$i" "$line" "true"
      fi
    done < $vpns_file
  fi

  # Use Multi IPs
  if [ "$USE_MULTI_IP" = true ]; then
    STATUS=1
    echo -e "${GREEN}USE_MULTI_IP is enabled, using multi ip..${NOCOLOUR}" 
    if [ ! -f "$multi_ip_file" ]; then
      echo -e "${RED}Multi IP file $multi_ip_file does not exist, exiting..${NOCOLOUR}"
      exit 1
    fi

    # Remove special character ^M from multi ip file
    sed -i 's/\r//g' $multi_ip_file
    
    i=0;
    while IFS= read -r line || [ -n "$line" ]; do
      if [[ "$line" =~ ^[^#].* ]]; then
        i=`expr $i + 1`
        start_containers "$i" "$line" "false"
      fi
    done < $multi_ip_file
  fi

  # Use Proxies
  if [ "$USE_PROXIES" = true ]; then
    STATUS=1
    echo -e "${GREEN}USE_PROXIES is enabled, using proxies..${NOCOLOUR}" 
    if [ ! -f "$proxies_file" ]; then
      echo -e "${RED}Proxies file $proxies_file does not exist, exiting..${NOCOLOUR}"
      exit 1
    fi

    # Remove special character ^M from proxies file
    sed -i 's/\r//g' $proxies_file
    
    i=0;
    while IFS= read -r line || [ -n "$line" ]; do
      if [[ "$line" =~ ^[^#].* ]]; then
        i=`expr $i + 1`
        start_containers "$i" "$line"
      fi
    done < $proxies_file 
  fi

  if [[ $STATUS == 1 ]]; then
    # Generate device Ids
    generate_device_ids
  fi

  if [[ $STATUS == 0 ]]; then
    echo -e "${RED}No Network configuration is specified. Script will not start unless specified in properties.conf ..Exiting..${NOCOLOUR}"
  fi
  exit 1
fi

if [[ "$1" == "--delete" ]]; then
  echo -e "\n\nDeleting Containers and networks.."
  
  # Delete containers by container names
  if [ -f "$container_names_file" ]; then
    for i in `cat $container_names_file`; do 
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
    for i in `cat $networks_file`; do
      sudo docker network rm $i
    done
    # Delete network file
    rm $networks_file
  fi

  # Delete IP tables
  k=1
  if [ "$USE_MULTI_IP" = true ]; then
      if [ -f "$multi_ip_file" ]; then
        for ip in `cat $multi_ip_file`; do
          subnet_number=`expr 32 + $k`
          sudo iptables -t nat -D POSTROUTING -s 192.168.$subnet_number.0/24 -j SNAT --to-source $ip
          k=`expr $k +1`
        done
      fi
  fi
  
  for file in "${files_to_be_removed[@]}"; do
    if [ -f "$file" ]; then
      rm $file
    fi
  done
  
  for folder in "${folders_to_be_removed[@]}"; do
    if [ -d "$folder" ]; then
      rm -Rf $folder;
    fi
  done
  exit 1
fi

if [[ "$1" == "--deleteBackup" ]]; then
  echo -e "\n\nDeleting backup folders and files.."

  for file in "${files_to_be_removed[@]}"; do
    if [ -f "$file" ]; then
      echo -e "${RED}File $file still exists, there might be containers still running. Please stop them and delete before running the script. Exiting..${NOCOLOUR}"
      echo -e "To stop and delete containers run the following command\n"
      echo -e "${YELLOW}sudo bash internetIncome.sh --delete${NOCOLOUR}\n"
      exit 1
    fi
  done
  
  for folder in "${folders_to_be_removed[@]}"; do
    if [ -d "$folder" ]; then
      echo -e "${RED}Folder $folder still exists, there might be containers still running. Please stop them and delete before running the script. Exiting..${NOCOLOUR}"
      echo -e "To stop and delete containers run the following command\n"
      echo -e "${YELLOW}sudo bash internetIncome.sh --delete${NOCOLOUR}\n"
      exit 1
    fi
  done
    
  for file in "${back_up_files[@]}"; do
    if [ -f "$file" ]; then
      rm $file
    fi
  done
  
  for folder in "${back_up_folders[@]}"; do
    if [ -d "$folder" ]; then
      rm -Rf $folder;
    fi
  done
  exit 1
fi

echo -e "Valid options are: ${RED}--start${NOCOLOUR}, ${RED}--delete${NOCOLOUR}, ${RED}--deleteBackup${NOCOLOUR}"
