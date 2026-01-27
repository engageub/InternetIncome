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
proxyrack_file="proxyrack.txt"
networks_file="networks.txt"
mysterium_file="mysterium.txt"
mysterium_data_folder="mysterium-data"
ebesucher_file="ebesucher.txt"
adnade_file="adnade.txt"
adnade_data_folder="adnadedata"
adnade_containers_file="adnadecontainers.txt"
firefox_containers_file="firefoxcontainers.txt"
chrome_containers_file="chromecontainers.txt"
bitping_data_folder="bitping-data"
urnetwork_data_folder="urnetwork-data"
firefox_data_folder="firefoxdata"
firefox_profile_data="firefoxprofiledata"
firefox_profile_zipfile="firefoxprofiledata.zip"
chrome_data_folder="chromedata"
chrome_profile_data="chromeprofiledata"
chrome_profile_zipfile="chromeprofiledata.zip"
restart_file="restart.sh"
dns_resolver_file="resolv.conf"
earn_fm_config_file="earnfm_config.json"
traffmonetizer_data_folder="traffmonetizerdata"
network3_data_folder="network3-data"
titan_data_folder="titan-data"
required_files=($banner_file $properties_file $firefox_profile_zipfile $restart_file $chrome_profile_zipfile)
files_to_be_removed=($earn_fm_config_file $dns_resolver_file $containers_file $container_names_file $networks_file $mysterium_file $ebesucher_file $adnade_file $adnade_containers_file $firefox_containers_file $chrome_containers_file)
folders_to_be_removed=($adnade_data_folder $firefox_data_folder $firefox_profile_data $earnapp_data_folder $chrome_data_folder $chrome_profile_data)
back_up_folders=($titan_data_folder $network3_data_folder $bitping_data_folder $urnetwork_data_folder $traffmonetizer_data_folder $mysterium_data_folder)
back_up_files=($earnapp_file $proxyrack_file)
container_pulled=false
docker_in_docker_detected=false

# Mysterium and ebesucher first port
mysterium_first_port=2000
ebesucher_first_port=3000
adnade_first_port=4000

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

# Check for open ports
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

  local i=$1
  local proxy=$2
  local DNS_VOLUME="-v $PWD/$dns_resolver_file:/etc/resolv.conf:ro"
  local TUN_DNS_VOLUME

  if [ "$container_pulled" = false ]; then
    # For users with Docker-in-Docker, the PWD path is on the host where Docker is installed.
    # The files are created in the same path as the inner Docker path.
    printf 'nameserver 8.8.8.8\nnameserver 8.8.4.4\nnameserver 1.1.1.1\nnameserver 1.0.0.1\nnameserver 9.9.9.9\n' > $dns_resolver_file;
    if [ ! -f $dns_resolver_file ]; then
      echo -e "${RED}There is a problem creating resolver file. Exiting..${NOCOLOUR}";
      exit 1;
    fi
    if sudo docker run --rm -v "$PWD:/output" docker:18.06.2-dind sh -c "if [ ! -f /output/$dns_resolver_file ]; then exit 0; else exit 1; fi"; then
      docker_in_docker_detected=true
    fi
    sudo docker run --rm -v $PWD:/output docker:18.06.2-dind sh -c "if [ ! -f /output/$dns_resolver_file ]; then printf 'nameserver 8.8.8.8\nnameserver 8.8.4.4\nnameserver 1.1.1.1\nnameserver 1.0.0.1\nnameserver 9.9.9.9\n' > /output/$dns_resolver_file; printf 'Docker-in-Docker is detected. The script runs with limited features.\nThe files and folders are created in the same path on the host where your parent docker is installed.\n'; fi"
  fi

  if [[ "$ENABLE_LOGS" != true ]]; then
    LOGS_PARAM="--log-driver none"
    TUN_LOG_PARAM="silent"
  else
    LOGS_PARAM="--log-driver=json-file --log-opt max-size=100k"
    TUN_LOG_PARAM="debug"
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
      if [ "$EBESUCHER_USE_CHROME" = true ]; then
          ebesucher_port="-p $ebesucher_first_port:3000 "
      else
          ebesucher_port="-p $ebesucher_first_port:5800 "
      fi
    fi

    if [[ $ADNADE_USERNAME ]]; then
      adnade_first_port=$(check_open_ports $adnade_first_port 1)
      if ! expr "$adnade_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $adnade_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Adnade. Resolve or disable Adnade to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      adnade_port="-p $adnade_first_port:5900 "
    fi

    combined_ports=$mysterium_port$ebesucher_port$adnade_port
    echo -e "${GREEN}Starting Proxy container..${NOCOLOUR}"
    # Starting tun containers
    if [ "$container_pulled" = false ]; then
      if [ "$USE_SOCKS5_DNS" = true ]; then
        sudo docker pull ghcr.io/heiher/hev-socks5-tunnel:latest
      else
        sudo docker pull xjasonlyu/tun2socks:v2.6.0
      fi
    fi
    if [ "$USE_SOCKS5_DNS" = true ]; then
      TUN_DNS_VOLUME="$DNS_VOLUME"
    elif [ "$USE_DNS_OVER_HTTPS" = true ]; then
      EXTRA_COMMANDS='echo -e "options use-vc\nnameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf;ip rule add iif lo ipproto udp dport 53 lookup main;'
    else
      TUN_DNS_VOLUME="$DNS_VOLUME"
      EXTRA_COMMANDS='ip rule add iif lo ipproto udp dport 53 lookup main;'
    fi
    if [[ "$USE_SOCKS5_DNS" == "true" && "$proxy" == socks5://* ]]; then
      SOCKS_PROXY=$proxy
      # Strip scheme
      SOCKS_NO_SCHEME="${SOCKS_PROXY#socks5://}"
      # If auth exists, split it
      if [[ "$SOCKS_NO_SCHEME" == *@* ]]; then
        SOCKS_CREDS="${SOCKS_NO_SCHEME%@*}"
        SOCKS_HOSTPORT="${SOCKS_NO_SCHEME#*@}"
        SOCKS_USER="${SOCKS_CREDS%%:*}"
        SOCKS_PASS="${SOCKS_CREDS#*:}"
      else
        SOCKS_HOSTPORT="$SOCKS_NO_SCHEME"
        SOCKS_USER=""
        SOCKS_PASS=""
      fi
      SOCKS_ADDR="${SOCKS_HOSTPORT%%:*}"
      SOCKS_PORT="${SOCKS_HOSTPORT##*:}"
      if [[ "$ENABLE_LOGS" != true ]]; then
        TUN_LOG_PARAM="warn"
      fi
      if CONTAINER_ID=$(sudo docker run --name tun$UNIQUE_ID$i $LOGS_PARAM $TUN_DNS_VOLUME --restart=always -e LOG_LEVEL=$TUN_LOG_PARAM -v '/dev/net/tun:/dev/net/tun' --cap-add=NET_ADMIN $combined_ports -e SOCKS5_ADDR="$SOCKS_ADDR" -e SOCKS5_PORT="$SOCKS_PORT" -e SOCKS5_USERNAME="$SOCKS_USER" -e SOCKS5_PASSWORD="$SOCKS_PASS" -d ghcr.io/heiher/hev-socks5-tunnel:latest); then
        echo "$CONTAINER_ID" | tee -a $containers_file
        echo "tun$UNIQUE_ID$i" | tee -a $container_names_file
      else
        echo -e "${RED}Failed to start container for proxy. Exiting..${NOCOLOUR}"
        exit 1
      fi
    else 
      if CONTAINER_ID=$(sudo docker run --name tun$UNIQUE_ID$i $LOGS_PARAM $TUN_DNS_VOLUME --restart=always -e LOGLEVEL=$TUN_LOG_PARAM -e PROXY=$proxy -e EXTRA_COMMANDS="$EXTRA_COMMANDS" -v '/dev/net/tun:/dev/net/tun' --cap-add=NET_ADMIN $combined_ports -d xjasonlyu/tun2socks:v2.6.0); then
        echo "$CONTAINER_ID" | tee -a $containers_file
        echo "tun$UNIQUE_ID$i" | tee -a $container_names_file
      else
        echo -e "${RED}Failed to start container for proxy. Exiting..${NOCOLOUR}"
        exit 1
      fi
    fi
    sleep 1
  fi

  # Starting Mysterium container
  if [[ "$MYSTERIUM" = true && ! $NETWORK_TUN ]]; then
    echo -e "${GREEN}Starting Mysterium container..${NOCOLOUR}"
    echo -e "${GREEN}Copy the following node url and paste in your browser${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $mysterium_file in the same folder${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull mysteriumnetwork/myst:latest
    fi
    if [[ ! $proxy ]]; then
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
    if CONTAINER_ID=$(sudo docker run -d --name myst$UNIQUE_ID$i --cap-add=NET_ADMIN $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME -v $PWD/$mysterium_data_folder/node$i:/var/lib/mysterium-node --restart unless-stopped $myst_port mysteriumnetwork/myst:latest service --agreed-terms-and-conditions); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "myst$UNIQUE_ID$i" | tee -a $container_names_file
      echo "http://127.0.0.1:$mysterium_first_port" |tee -a $mysterium_file
      mysterium_first_port=`expr $mysterium_first_port + 1`
    else
      echo -e "${RED}Failed to start container for Mysterium. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Mysterium Node is not enabled. Ignoring Mysterium..${NOCOLOUR}"
    fi
  fi

  # Starting Ebesucher Chrome container
  if [[ $EBESUCHER_USERNAME && "$EBESUCHER_USE_CHROME" = true ]]; then
    if [ "$docker_in_docker_detected" = true ]; then
      echo -e "${RED}Adnade and Ebesucher are not supported now in Docker-in-Docker. Please use custom chrome or custom firefox in test branch and login manually. Exiting..${NOCOLOUR}";
      exit 1
    fi
    if [ "$container_pulled" = false ]; then
      sudo docker pull lscr.io/linuxserver/chromium:latest

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

      if CONTAINER_ID=$(sudo docker run -d --name dind$UNIQUE_ID$i $LOGS_PARAM $DNS_VOLUME -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/usr/bin/docker -v $PWD:/chrome docker:18.06.2-dind /bin/sh -c 'apk add --no-cache bash && cd /chrome && chmod +x /chrome/restart.sh && while true; do sleep 3600; /chrome/restart.sh --restartChrome; done'); then
        echo "Chrome restart container started"
        echo "$CONTAINER_ID" | tee -a $containers_file
        echo "dind$UNIQUE_ID$i" | tee -a $container_names_file
      else
        echo -e "${RED}Failed to start container for ebesucher chrome restart. Exiting..${NOCOLOUR}"
        exit 1
      fi
    fi

    # Create folder and copy files
    mkdir -p $PWD/$chrome_data_folder/data$i
    sudo chown -R 911:911 $PWD/$chrome_profile_data
    sudo cp -r $PWD/$chrome_profile_data $PWD/$chrome_data_folder/data$i
    sudo chown -R 911:911 $PWD/$chrome_data_folder/data$i

    if [[ ! $proxy ]]; then
      ebesucher_first_port=$(check_open_ports $ebesucher_first_port 1)
      if ! expr "$ebesucher_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $ebesucher_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Ebesucher. Resolve or disable Ebesucher to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      eb_port="-p $ebesucher_first_port:3000 "
    fi

    if CONTAINER_ID=$(sudo docker run -d --name ebesucher$UNIQUE_ID$i $LOGS_PARAM $DNS_VOLUME $NETWORK_TUN --security-opt seccomp=unconfined -e TZ=Etc/UTC -e CHROME_CLI="https://www.ebesucher.com/surfbar/$EBESUCHER_USERNAME" -e CUSTOM_USER="internetincome" -e PASSWORD="internetincome" -v $PWD/$chrome_data_folder/data$i/$chrome_profile_data:/config --shm-size="1gb" $eb_port lscr.io/linuxserver/chromium:latest); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "ebesucher$UNIQUE_ID$i" | tee -a $container_names_file
      echo "ebesucher$UNIQUE_ID$i" | tee -a $chrome_containers_file
      echo "http://127.0.0.1:$ebesucher_first_port" |tee -a $ebesucher_file
      ebesucher_first_port=`expr $ebesucher_first_port + 1`
    else
      echo -e "${RED}Failed to start container for Ebesucher. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Ebesucher username for chrome is not configured. Ignoring Ebesucher..${NOCOLOUR}"
    fi
  fi

  # Starting Ebesucher container
  if [[ $EBESUCHER_USERNAME && "$EBESUCHER_USE_CHROME" != true ]]; then
    if [ "$docker_in_docker_detected" = true ]; then
      echo -e "${RED}Adnade and Ebesucher are not supported now in Docker-in-Docker. Please use custom chrome or custom firefox in test branch and login manually. Exiting..${NOCOLOUR}";
      exit 1
    fi
    echo -e "${GREEN}Starting Ebesucher container..${NOCOLOUR}"
    echo -e "${GREEN}Copy the following node url and paste in your browser if required..${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $ebesucher_file in the same folder${NOCOLOUR}"
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

      if CONTAINER_ID=$(sudo docker run -d --name dind$UNIQUE_ID$i $LOGS_PARAM $DNS_VOLUME --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/usr/bin/docker -v $PWD:/firefox docker:18.06.2-dind /bin/sh -c 'apk add --no-cache bash && cd /firefox && chmod +x /firefox/restart.sh && while true; do sleep 3600; /firefox/restart.sh --restartFirefox; done'); then
        echo "Firefox restart container started"
        echo "$CONTAINER_ID" | tee -a $containers_file
        echo "dind$UNIQUE_ID$i" | tee -a $container_names_file
      else
        echo -e "${RED}Failed to start container for ebesucher firefox restart. Exiting..${NOCOLOUR}"
        exit 1
      fi
    fi

    # Create folder and copy files
    mkdir -p $PWD/$firefox_data_folder/data$i
    sudo chmod -R 777 $PWD/$firefox_profile_data
    cp -r $PWD/$firefox_profile_data/* $PWD/$firefox_data_folder/data$i/
    sudo chmod -R 777 $PWD/$firefox_data_folder/data$i
    if [[ ! $proxy ]]; then
      ebesucher_first_port=$(check_open_ports $ebesucher_first_port 1)
      if ! expr "$ebesucher_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $ebesucher_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Ebesucher. Resolve or disable Ebesucher to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      eb_port="-p $ebesucher_first_port:5800"
    fi
    if CONTAINER_ID=$(sudo docker run -d --name ebesucher$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME --restart=always -e FF_OPEN_URL="https://www.ebesucher.com/surfbar/$EBESUCHER_USERNAME" -e VNC_LISTENING_PORT=-1 -e VNC_PASSWORD="internetincome" -v $PWD/$firefox_data_folder/data$i:/config:rw $eb_port jlesage/firefox); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "ebesucher$UNIQUE_ID$i" | tee -a $container_names_file
      echo "ebesucher$UNIQUE_ID$i" | tee -a $firefox_containers_file
      echo "http://127.0.0.1:$ebesucher_first_port" |tee -a $ebesucher_file
      ebesucher_first_port=`expr $ebesucher_first_port + 1`
    else
      echo -e "${RED}Failed to start container for Ebesucher. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Ebesucher username is not configured. Ignoring Ebesucher..${NOCOLOUR}"
    fi
  fi

  # Starting Adnade container
  if [[ $ADNADE_USERNAME ]]; then
    if [ "$docker_in_docker_detected" = true ]; then
      echo -e "${RED}Adnade and Ebesucher are not supported now in Docker-in-Docker. Please use custom chrome or custom firefox in test branch and login manually. Exiting..${NOCOLOUR}";
      exit 1
    fi
    echo -e "${GREEN}Starting Adnade container..${NOCOLOUR}"
    echo -e "${GREEN}Copy the following node url and paste in your browser if required..${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $adnade_file in the same folder${NOCOLOUR}"
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
        echo -e "${RED}Firefox profile Data folder does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi

      if CONTAINER_ID=$(sudo docker run -d --name adnadedind$UNIQUE_ID$i $LOGS_PARAM $DNS_VOLUME --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/usr/bin/docker -v $PWD:/firefox docker:18.06.2-dind /bin/sh -c 'apk add --no-cache bash && cd /firefox && chmod +x /firefox/restart.sh && while true; do sleep 7200; /firefox/restart.sh --restartAdnade; done'); then
        echo "Firefox restart container started"
        echo "$CONTAINER_ID" | tee -a $containers_file
        echo "adnadedind$UNIQUE_ID$i" | tee -a $container_names_file
      else
        echo -e "${RED}Failed to start container for adnade firefox restart. Exiting..${NOCOLOUR}"
        exit 1
      fi
    fi

    # Create folder and copy files
    mkdir -p $PWD/$adnade_data_folder/data$i
    sudo chmod -R 777 $PWD/$firefox_profile_data
    cp -r $PWD/$firefox_profile_data/* $PWD/$adnade_data_folder/data$i/
    sudo chmod -R 777 $PWD/$adnade_data_folder/data$i
    if [[ ! $proxy ]]; then
      adnade_first_port=$(check_open_ports $adnade_first_port 1)
      if ! expr "$adnade_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $adnade_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Adnade. Resolve or disable Adnade to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      ad_port="-p $adnade_first_port:5900"
    fi
    if CONTAINER_ID=$(sudo docker run -d --name adnade$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME --restart=always -e FF_OPEN_URL="https://adnade.net/view.php?user=$ADNADE_USERNAME&multi=4" -e VNC_LISTENING_PORT=-1 -e WEB_LISTENING_PORT=5900 -e VNC_PASSWORD="internetincome" -v $PWD/$adnade_data_folder/data$i:/config:rw $ad_port jlesage/firefox); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "adnade$UNIQUE_ID$i" | tee -a $container_names_file
      echo "adnade$UNIQUE_ID$i" | tee -a $adnade_containers_file
      echo "http://127.0.0.1:$adnade_first_port" |tee -a $adnade_file
      adnade_first_port=`expr $adnade_first_port + 1`
    else
      echo -e "${RED}Failed to start container for Adnade. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Adnade username is not configured. Ignoring Adnade..${NOCOLOUR}"
    fi
  fi

  # Starting BitPing container
  if [[ $BITPING_EMAIL && $BITPING_PASSWORD ]]; then
    echo -e "${GREEN}Starting Bitping container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull bitping/bitpingd:latest
    fi
    # Create bitping folder
    mkdir -p $PWD/$bitping_data_folder/data$i/.bitpingd
    sudo chmod -R 777 $PWD/$bitping_data_folder/data$i/.bitpingd
    if [ ! -f "$PWD/$bitping_data_folder/data$i/.bitpingd/node.db" ]; then
        sudo docker run --rm $NETWORK_TUN -v "$PWD/$bitping_data_folder/data$i/.bitpingd:/root/.bitpingd" --entrypoint /app/bitpingd bitping/bitpingd:latest login --email $BITPING_EMAIL --password $BITPING_PASSWORD
    fi
    if CONTAINER_ID=$(sudo docker run -d --name bitping$UNIQUE_ID$i --restart=always $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME -v "$PWD/$bitping_data_folder/data$i/.bitpingd:/root/.bitpingd" bitping/bitpingd:latest); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "bitping$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for BitPing. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}BitPing Node is not enabled. Ignoring BitPing..${NOCOLOUR}"
    fi
  fi

  # Starting Repocket container
  if [[ $REPOCKET_EMAIL && $REPOCKET_API ]]; then
    echo -e "${GREEN}Starting Repocket container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull repocket/repocket
    fi
    if CONTAINER_ID=$(sudo docker run -d --name repocket$UNIQUE_ID$i --restart=always $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME -e RP_EMAIL=$REPOCKET_EMAIL -e RP_API_KEY=$REPOCKET_API repocket/repocket); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "repocket$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for Repocket. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Repocket Email or Api is not configured. Ignoring Repocket..${NOCOLOUR}"
    fi
  fi

  # Starting Earn FM container
  if [[ $EARN_FM_API && "$USE_EARN_FM_FLEETSHARE" != true ]]; then
    echo -e "${GREEN}Starting EarnFM container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull earnfm/earnfm-client:latest
    fi
    if CONTAINER_ID=$(sudo docker run -d --name earnfm$UNIQUE_ID$i --restart=always $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME -e EARNFM_TOKEN=$EARN_FM_API earnfm/earnfm-client:latest); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "earnfm$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for EarnFM. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}EarnFM Api is not configured. Ignoring EarnFM..${NOCOLOUR}"
    fi
  fi

  # Starting Earn FM Fleetshare container
  if [[ $EARN_FM_API && "$USE_EARN_FM_FLEETSHARE" = true ]]; then
    if [ "$container_pulled" = false ]; then
      echo -e "${GREEN}Starting EarnFM Fleetshare container..${NOCOLOUR}"
      sudo docker pull earnfm/fleetshare:latest
      if [ -f "$proxies_file" ]; then
	SOCKS_PROXIES=()
        while IFS= read -r line; do
          # Skip empty lines
          [[ -z "$line" ]] && continue
          if [[ "$line" == socks5://* ]]; then
            # Remove socks5:// prefix for config format
            proxy="${line#socks5://}"
            SOCKS_PROXIES+=("\"$proxy\"")
          fi
        done < "$proxies_file"
        if [[ ${#SOCKS_PROXIES[@]} -eq 0 ]]; then
          echo -e "${RED}Proxies file $proxies_file does not have socks5 proxies. Exiting..${NOCOLOUR}"
          exit 1
        fi
      	cat > "$earn_fm_config_file" <<-EOF
	{
	  "apiKey": "$EARN_FM_API",
	  "devices": {
	    "subnets": [],
	    "socksProxies": [$(IFS=,; echo "${SOCKS_PROXIES[*]}")]
	  },
	  "debug": false
	}
	EOF
        if [ ! -f "$earn_fm_config_file" ]; then
          echo -e "${RED}Config file could not be generated for EarnFM Fleetshare. Exiting..${NOCOLOUR}"
	  exit 1
        fi
        if CONTAINER_ID=$(sudo docker run -d --name earnfm$UNIQUE_ID$i --restart=always $LOGS_PARAM $DNS_VOLUME -v $PWD/$earn_fm_config_file:/app/config.json earnfm/fleetshare:latest); then
          echo "$CONTAINER_ID" | tee -a $containers_file
          echo "earnfm$UNIQUE_ID$i" | tee -a $container_names_file
        else
          echo -e "${RED}Failed to start container for EarnFM. Exiting..${NOCOLOUR}"
          exit 1
        fi
      else
	echo -e "${RED}Proxies file $proxies_file does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}EarnFM Fleetshare is not configured. Ignoring EarnFM Fleetshare..${NOCOLOUR}"
    fi
  fi

  # Starting PacketSDK container
  if [[ $PACKET_SDK_APP_KEY ]]; then
    echo -e "${GREEN}Starting PacketSDK container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull packetsdk/packetsdk
    fi
    if CONTAINER_ID=$(sudo docker run -d --name packetsdk$UNIQUE_ID$i --restart=always $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME packetsdk/packetsdk -appkey=$PACKET_SDK_APP_KEY); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "packetsdk$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for PacketSDK. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}PacketSDK API is not configured. Ignoring PacketSDK..${NOCOLOUR}"
    fi
  fi

  # Starting Gaganode container
  if [[ $GAGANODE_TOKEN ]]; then
    echo -e "${GREEN}Starting Gaganode container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull xterna/gaga-node
    fi
    if CONTAINER_ID=$(sudo docker run -d --name gaganode$UNIQUE_ID$i --restart=always $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME -e TOKEN=$GAGANODE_TOKEN xterna/gaga-node); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "gaganode$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for Gaganode. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Gaganode Token is not configured. Ignoring Gaganode..${NOCOLOUR}"
    fi
  fi

  # Starting Traffmonetizer container
  if [[ $TRAFFMONETIZER_TOKEN ]]; then
    echo -e "${GREEN}Starting Traffmonetizer container..${NOCOLOUR}"
    if [ "$CPU_ARCH" == "aarch64" ] || [ "$CPU_ARCH" == "arm64" ]; then
      traffmonetizer_image="traffmonetizer/cli_v2:arm64v8"
    elif [ "$CPU_ARCH" == "armv7l" ]; then
      traffmonetizer_image="traffmonetizer/cli_v2:arm32v7"
    else
      traffmonetizer_image="--platform=linux/amd64 traffmonetizer/cli_v2"
    fi
    if [ "$container_pulled" = false ]; then
      sudo docker pull $traffmonetizer_image
    fi
    mkdir -p $PWD/$traffmonetizer_data_folder/data$i
    sudo chmod -R 777 $PWD/$traffmonetizer_data_folder/data$i
    traffmonetizer_volume="-v $PWD/$traffmonetizer_data_folder/data$i:/app/traffmonetizer"
    if CONTAINER_ID=$(sudo  docker run -d --name traffmon$UNIQUE_ID$i --restart=always $LOGS_PARAM $DNS_VOLUME $NETWORK_TUN $traffmonetizer_volume $traffmonetizer_image start accept --device-name $DEVICE_NAME$i --token $TRAFFMONETIZER_TOKEN); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "traffmon$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for Traffmonetizer. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Traffmonetizer Token is not configured. Ignoring Traffmonetizer..${NOCOLOUR}"
    fi
  fi

  # Starting ProxyRack container
  if [[ $PROXYRACK_API ]]; then
    echo -e "${GREEN}Starting Proxyrack container..${NOCOLOUR}"
    for loop_count in {1..500}; do
      if [ "$loop_count" -eq 500 ]; then
        echo -e "${RED}Unique UUID cannot be generated for ProxyRack. Exiting..${NOCOLOUR}"
        exit 1
      fi
      RANDOM_ID=`cat /dev/urandom | LC_ALL=C tr -dc 'A-F0-9' | dd bs=1 count=64 2>/dev/null`
      if [ -f $proxyrack_file ]; then
        if ! grep -qF "$RANDOM_ID" "$proxyrack_file"; then
          break
        fi
      else
        break;
      fi
    done
    if [ "$container_pulled" = false ]; then
      sudo docker pull --platform=linux/amd64 proxyrack/pop
    fi
    if [ -f $proxyrack_file ] && proxyrack_uuid=$(sed "${i}q;d" $proxyrack_file);then
      if [[ $proxyrack_uuid ]];then
        echo $proxyrack_uuid
      else
        echo "Proxyrack UUID does not exist, creating UUID"
        proxyrack_uuid=$RANDOM_ID
        printf "%s\n" "$proxyrack_uuid" | tee -a $proxyrack_file
      fi
    else
      echo "Proxyrack UUID does not exist, creating UUID"
      proxyrack_uuid=$RANDOM_ID
      printf "%s\n" "$proxyrack_uuid" | tee -a $proxyrack_file
    fi

    if CONTAINER_ID=$(sudo docker run -d --name proxyrack$UNIQUE_ID$i --platform=linux/amd64 $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME --restart=always -e UUID=$proxyrack_uuid  -e DEVICE_NAME=$DEVICE_NAME$i -e API_KEY=$PROXYRACK_API proxyrack/pop); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "proxyrack$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for Proxyrack. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Proxyrack is not enabled. Ignoring Proxyrack..${NOCOLOUR}"
    fi
  fi

  # Starting ProxyBase container
  if [[ "$PROXYBASE_ACCOUNT_ID" ]]; then
    echo -e "${GREEN}Starting Proxybase container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull proxybase/proxybase
    fi
    if CONTAINER_ID=$(sudo docker run -d --name proxybase$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME --restart=always -e DEVICE_NAME=$DEVICE_NAME$i -e USER_ID=$PROXYBASE_ACCOUNT_ID proxybase/proxybase); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "proxybase$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for Proxybase. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Proxybase is not enabled. Ignoring Proxybase..${NOCOLOUR}"
    fi
  fi

  # Starting IPRoyals pawns container
  if [[ $IPROYALS_EMAIL && $IPROYALS_PASSWORD ]]; then
    echo -e "${GREEN}Starting IPRoyals container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull iproyal/pawns-cli:latest
    fi
    if CONTAINER_ID=$(sudo docker run -d --name pawns$UNIQUE_ID$i --restart=always $LOGS_PARAM $DNS_VOLUME $NETWORK_TUN iproyal/pawns-cli:latest -email=$IPROYALS_EMAIL -password=$IPROYALS_PASSWORD -device-name=$DEVICE_NAME$i -device-id=$DEVICE_NAME$i -accept-tos); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "pawns$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for IPRoyals. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}IPRoyals Email or Password is not configured. Ignoring IPRoyals..${NOCOLOUR}"
    fi
  fi

  # Starting CastarSDK container
  if [[ $CASTAR_SDK_KEY ]]; then
    echo -e "${GREEN}Starting CastarSDK container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull ghcr.io/adfly8470/castarsdk/castarsdk@sha256:fc07c70982ae1869181acd81f0b7314b03e0601794d4e7532b7f8435e971eaa8
    fi
    if CONTAINER_ID=$(sudo docker run -d --name castarsdk$UNIQUE_ID$i --restart=always $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME -e KEY=$CASTAR_SDK_KEY ghcr.io/adfly8470/castarsdk/castarsdk@sha256:fc07c70982ae1869181acd81f0b7314b03e0601794d4e7532b7f8435e971eaa8); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "castarsdk$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for CastarSDK. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}CastarSDK is not configured. Ignoring CastarSDK..${NOCOLOUR}"
    fi
  fi

  # Starting Wipter container
  if [[ $WIPTER_EMAIL && $WIPTER_PASSWORD ]]; then
    echo -e "${GREEN}Starting Wipter container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull ghcr.io/adfly8470/wipter/wipter@sha256:9b1a7742bfbbd68e86eea1719f606c7d10c884e2578a4fb35f109eed387619cd
    fi
    if CONTAINER_ID=$(sudo docker run -d --name wipter$UNIQUE_ID$i --restart=always $LOGS_PARAM $DNS_VOLUME $NETWORK_TUN -e WIPTER_EMAIL=$WIPTER_EMAIL -e WIPTER_PASSWORD=$WIPTER_PASSWORD ghcr.io/adfly8470/wipter/wipter@sha256:9b1a7742bfbbd68e86eea1719f606c7d10c884e2578a4fb35f109eed387619cd); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "wipter$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for Wipter. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Wipter Email or Password is not configured. Ignoring Wipter..${NOCOLOUR}"
    fi
  fi

  # Starting PacketShare container
  if [[ $PACKETSHARE_EMAIL && $PACKETSHARE_PASSWORD ]]; then
    echo -e "${GREEN}Starting PacketShare container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull packetshare/packetshare
    fi
    if CONTAINER_ID=$(sudo docker run -d --name packetshare$UNIQUE_ID$i --restart=always $LOGS_PARAM $DNS_VOLUME $NETWORK_TUN packetshare/packetshare -accept-tos -email=$PACKETSHARE_EMAIL -password=$PACKETSHARE_PASSWORD); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "packetshare$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for PacketShare. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}PacketShare Email or Password is not configured. Ignoring PacketShare..${NOCOLOUR}"
    fi
  fi

  # Starting Depin Chrome Extensions container
  if [[ $GRASS_EMAIL && $GRASS_PASSWORD ]] || [[ $GRADIENT_EMAIL && $GRADIENT_PASSWORD ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull carbon2029/dockweb
    fi
    if [[ $GRASS_EMAIL && $GRASS_PASSWORD ]]; then
      grass_env="-e GRASS_USER=$GRASS_EMAIL -e GRASS_PASS=$GRASS_PASSWORD"
    fi
    if [[ $GRADIENT_EMAIL && $GRADIENT_PASSWORD ]]; then
      gradient_env="-e GRADIENT_EMAIL=$GRADIENT_EMAIL -e GRADIENT_PASS=$GRADIENT_PASSWORD"
    fi
    if CONTAINER_ID=$(sudo docker run -d --name depinext$UNIQUE_ID$i --restart=always $LOGS_PARAM $DNS_VOLUME $NETWORK_TUN $grass_env $gradient_env carbon2029/dockweb); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "depinext$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for Depin Extensions. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Depin Extensions are not configured. Ignoring Depin Extensions..${NOCOLOUR}"
    fi
  fi

  # Starting Honeygain container
  if [[ $HONEYGAIN_EMAIL && $HONEYGAIN_PASSWORD ]]; then
    echo -e "${GREEN}Starting Honeygain container..${NOCOLOUR}"
    if [[ $NETWORK_TUN ]]; then
      if [ "$CPU_ARCH" == "x86_64" ] || [ "$CPU_ARCH" == "amd64" ]; then
        honeygain_image="honeygain/honeygain:0.6.6"
      else
        honeygain_image="honeygain/honeygain"
      fi
    else
      honeygain_image="honeygain/honeygain"
    fi
    if [ "$container_pulled" = false ]; then
      sudo docker pull $honeygain_image
    fi
    if CONTAINER_ID=$(sudo docker run -d --name honey$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME --restart=always $honeygain_image -tou-accept -email $HONEYGAIN_EMAIL -pass $HONEYGAIN_PASSWORD -device $DEVICE_NAME$i); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "honey$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for Honeygain. Exiting..${NOCOLOUR}"
      exit 1
  fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Honeygain Email or Password is not configured. Ignoring Honeygain..${NOCOLOUR}"
    fi
  fi

  # Starting Peer2Profit container
  if [[ $PEER2PROFIT_EMAIL ]]; then
    echo -e "${GREEN}Starting Peer2Profit container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull --platform=linux/amd64 enwaiax/peer2profit
    fi
    if CONTAINER_ID=$(sudo docker run -d --platform=linux/amd64 --name peer2profit$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME --restart always -e email=$PEER2PROFIT_EMAIL enwaiax/peer2profit); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "peer2profit$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for Peer2Profit. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Peer2Profit Email is not configured. Ignoring Peer2Profit..${NOCOLOUR}"
    fi
  fi

  # Starting AntGain container
  if [[ $ANTGAIN_API_KEY ]]; then
    echo -e "${GREEN}Starting AntGain container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull --platform=linux/amd64 pinors/antgain-cli:latest
    fi
    if CONTAINER_ID=$(sudo docker run -d --platform=linux/amd64 --name antgain$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME --restart always -e ANTGAIN_API_KEY=$ANTGAIN_API_KEY pinors/antgain-cli:latest run); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "antgain$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for AntGain. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}AntGain API is not configured. Ignoring AntGain..${NOCOLOUR}"
    fi
  fi

  # Starting WizardGain container
  if [[ $WIZARD_GAIN_EMAIL ]]; then
    echo -e "${GREEN}Starting WizardGain container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull wizardgain/worker:latest
    fi
    if CONTAINER_ID=$(sudo docker run -d --name wizardgain$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME --restart always -e EMAIL=$WIZARD_GAIN_EMAIL wizardgain/worker:latest); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "wizardgain$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for WizardGain. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}WizardGain Email is not configured. Ignoring WizardGain..${NOCOLOUR}"
    fi
  fi

  # Starting PacketStream container
  if [[ $PACKETSTREAM_CID ]]; then
    echo -e "${GREEN}Starting PacketStream container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull packetstream/psclient:latest
    fi
    if CONTAINER_ID=$(sudo docker run -d --name packetstream$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME --restart always -e HTTP_PROXY="" -e HTTPS_PROXY="" -e CID=$PACKETSTREAM_CID packetstream/psclient:latest); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "packetstream$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for PacketStream. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}PacketStream CID is not configured. Ignoring PacketStream..${NOCOLOUR}"
    fi
  fi

  # Starting Proxylite container
  if [[ $PROXYLITE_USER_ID ]]; then
    echo -e "${GREEN}Starting Proxylite container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull proxylite/proxyservice
    fi
    if CONTAINER_ID=$(sudo docker run -d --name proxylite$UNIQUE_ID$i --platform=linux/amd64 $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME  -e USER_ID=$PROXYLITE_USER_ID --restart=always proxylite/proxyservice); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "proxylite$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for Proxylite. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Proxylite is not configured. Ignoring Proxylite..${NOCOLOUR}"
    fi
  fi

  # Starting URnetwork container
  if [[ $UR_AUTH_TOKEN ]]; then
    echo -e "${GREEN}Starting URnetwork container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull bringyour/community-provider:latest
      # Create URnetwork folder
      mkdir -p $PWD/$urnetwork_data_folder/data/.urnetwork
      sudo chmod -R 777 $PWD/$urnetwork_data_folder/data/.urnetwork
      if [ ! -f "$PWD/$urnetwork_data_folder/data/.urnetwork/jwt" ]; then
        sudo docker run --rm $DNS_VOLUME $NETWORK_TUN -v "$PWD/$urnetwork_data_folder/data/.urnetwork:/root/.urnetwork" --entrypoint /usr/local/sbin/bringyour-provider bringyour/community-provider:latest auth $UR_AUTH_TOKEN
        sleep 1
        if [ ! -f "$PWD/$urnetwork_data_folder/data/.urnetwork/jwt" ]; then
          echo -e "${RED}JWT file could not be generated for URnetwork. Exiting..${NOCOLOUR}"
          exit 1
        fi
      fi
      if CONTAINER_ID=$(sudo docker run -d --name dindurnetwork$UNIQUE_ID$i $LOGS_PARAM $DNS_VOLUME --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/usr/bin/docker -v $PWD:/urnetwork docker:18.06.2-dind /bin/sh -c 'apk add --no-cache bash && cd /urnetwork && chmod +x /urnetwork/restart.sh && while true; do sleep 86400; /urnetwork/restart.sh --restartURnetwork; done'); then
        echo "URnetwork restart container started"
        echo "$CONTAINER_ID" | tee -a $containers_file
        echo "dindurnetwork$UNIQUE_ID$i" | tee -a $container_names_file
      else
        echo -e "${RED}Failed to start container for URnetwork restart. Exiting..${NOCOLOUR}"
        exit 1
      fi
    fi
    if CONTAINER_ID=$(sudo docker run -d --name urnetwork$UNIQUE_ID$i --restart=always $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME -v "$PWD/$urnetwork_data_folder/data/.urnetwork:/root/.urnetwork" bringyour/community-provider:latest provide); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "urnetwork$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for URnetwork. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}URnetwork Node is not enabled. Ignoring URnetwork..${NOCOLOUR}"
    fi
  fi

  # Starting Titan Network container
  if [[ $TITAN_HASH ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull nezha123/titan-edge
      mkdir -p $PWD/$titan_data_folder/data$i
      sudo chmod -R 777 $PWD/$titan_data_folder/data$i
      titan_volume="-v $PWD/$titan_data_folder/data$i:/root/.titanedge"
      if CONTAINER_ID=$(sudo  docker run -d --name titan$UNIQUE_ID$i --restart=always $LOGS_PARAM $DNS_VOLUME $NETWORK_TUN $titan_volume nezha123/titan-edge); then
        echo "$CONTAINER_ID" | tee -a $containers_file
        echo "titan$UNIQUE_ID$i" | tee -a $container_names_file
      else
        echo -e "${RED}Failed to start container for Titan Network. Exiting..${NOCOLOUR}"
        exit 1
      fi
      sleep 5
      sudo docker run --rm -it $titan_volume nezha123/titan-edge bind --hash=$TITAN_HASH https://api-test1.container1.titannet.io/api/v2/device/binding
      echo -e "${GREEN}The current script is designed to support only a single device for the Titan Network. Please create a new folder, download the InternetIncome script, and add the appropriate hash for the new device.${NOCOLOUR}"
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Titan Network Hash is not configured. Ignoring Titan Network..${NOCOLOUR}"
    fi
  fi

  # Starting Earnapp container
  if [ "$EARNAPP" = true ]; then
    echo -e "${GREEN}Starting Earnapp container..${NOCOLOUR}"
    echo -e "${GREEN}Copy the following node url and paste in your earnapp dashboard${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $earnapp_file in the same folder${NOCOLOUR}"
    for loop_count in {1..500}; do
      if [ "$loop_count" -eq 500 ]; then
        echo -e "${RED}Unique UUID cannot be generated for Earnapp. Exiting..${NOCOLOUR}"
        exit 1
      fi
      RANDOM_ID=`cat /dev/urandom | LC_ALL=C tr -dc 'a-f0-9' | dd bs=1 count=32 2>/dev/null`
      if [ -f $earnapp_file ]; then
        if ! grep -qF "$RANDOM_ID" "$earnapp_file"; then
          break
        fi
      else
        break;
      fi
    done
    date_time=`date "+%D %T"`
    if [ "$container_pulled" = false ]; then
      sudo docker pull fazalfarhan01/earnapp:lite
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

    if CONTAINER_ID=$(sudo docker run -d --health-interval=24h --name earnapp$UNIQUE_ID$i $LOGS_PARAM $DNS_VOLUME --restart=always $NETWORK_TUN -v $PWD/$earnapp_data_folder/data$i:/etc/earnapp -e EARNAPP_UUID=$uuid fazalfarhan01/earnapp:lite); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "earnapp$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for Earnapp. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Earnapp is not enabled. Ignoring Earnapp..${NOCOLOUR}"
    fi
  fi

  container_pulled=true
}

# Update and Install Docker
if [[ "$1" == "--install" ]]; then
  sudo apt-get update
  sudo apt-get -y install docker.io
  CPU_ARCH=`uname -m`
  if [ "$CPU_ARCH" == "aarch64" ] || [ "$CPU_ARCH" == "arm64" ]; then
    sudo docker run --privileged --rm tonistiigi/binfmt --install all
    sudo apt-get install qemu binfmt-support qemu-user-static
  fi
  # Check if Docker is installed
  if command -v docker &> /dev/null; then
    echo -e "${GREEN}Docker is installed.${NOCOLOUR}"
    docker --version
  else
    echo -e "${RED}Docker is not installed. There is a problem installing Docker.${NOCOLOUR}"
    echo "Please install Docker manually by following https://docs.docker.com/engine/install/"
  fi
  exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  echo -e "${RED}Docker is not installed, without which the script cannot start. Exiting..${NOCOLOUR}"
  echo -e "To install Docker and its dependencies, please run the following command\n"
  echo -e "${YELLOW}sudo bash internetIncome.sh --install${NOCOLOUR}\n"
  exit 1
fi

if [[ "$1" == "--start" ]]; then
  echo -e "\n\nStarting.."

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

  # Remove special characters ^M from properties file
  sed -i 's/\r//g' $properties_file

  # CPU architecture to get docker images
  CPU_ARCH=`uname -m`

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
  exit 1
fi

# Delete containers and networks
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

  # Delete files
  for file in "${files_to_be_removed[@]}"; do
    if [ -f "$file" ]; then
      rm $file
    fi
  done

  # Delete files for Docker-in-Docker
  sudo docker run --rm -v "$PWD:/output" docker:18.06.2-dind sh -c 'for file in "$@"; do if [ -f "/output/$file" ]; then rm "/output/$file"; fi; done' sh "${files_to_be_removed[@]}"

  # Delete folders
  for folder in "${folders_to_be_removed[@]}"; do
    if [ -d "$folder" ]; then
      rm -Rf $folder;
    fi
  done

  # Delete folders for Docker-in-Docker
  sudo docker run --rm -v "$PWD:/output" docker:18.06.2-dind sh -c 'for folder in "$@"; do if [ -d "/output/$folder" ]; then rm -rf "/output/$folder"; fi; done' sh "${folders_to_be_removed[@]}"

  exit 1
fi

# Delete backup files and folders
if [[ "$1" == "--deleteBackup" ]]; then
  echo -e "\n\nDeleting backup folders and files.."

  # Check if previous files exist
  for file in "${files_to_be_removed[@]}"; do
    if [ -f "$file" ]; then
      echo -e "${RED}File $file still exists, there might be containers still running. Please stop them and delete before running the script. Exiting..${NOCOLOUR}"
      echo -e "To stop and delete containers run the following command\n"
      echo -e "${YELLOW}sudo bash internetIncome.sh --delete${NOCOLOUR}\n"
      exit 1
    fi
  done

  # Check if previous folders exist
  for folder in "${folders_to_be_removed[@]}"; do
    if [ -d "$folder" ]; then
      echo -e "${RED}Folder $folder still exists, there might be containers still running. Please stop them and delete before running the script. Exiting..${NOCOLOUR}"
      echo -e "To stop and delete containers run the following command\n"
      echo -e "${YELLOW}sudo bash internetIncome.sh --delete${NOCOLOUR}\n"
      exit 1
    fi
  done

  # Delete backup files
  for file in "${back_up_files[@]}"; do
    if [ -f "$file" ]; then
      rm $file
    fi
  done

  # Delete backup files for Docker-in-Docker
  sudo docker run --rm -v "$PWD:/output" docker:18.06.2-dind sh -c 'for file in "$@"; do if [ -f "/output/$file" ]; then rm "/output/$file"; fi; done' sh "${back_up_files[@]}"

  # Delete backup folders
  for folder in "${back_up_folders[@]}"; do
    if [ -d "$folder" ]; then
      rm -Rf $folder;
    fi
  done

  # Delete backup folders for Docker-in-Docker
  sudo docker run --rm -v "$PWD:/output" docker:18.06.2-dind sh -c 'for folder in "$@"; do if [ -d "/output/$folder" ]; then rm -rf "/output/$folder"; fi; done' sh "${back_up_folders[@]}"

  exit 1
fi

echo -e "Valid options are: ${RED}--start${NOCOLOUR}, ${RED}--delete${NOCOLOUR}, ${RED}--deleteBackup${NOCOLOUR}"
