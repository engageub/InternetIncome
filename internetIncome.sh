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
proxybase_file="proxybase.txt"
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
CONFIG_DIR_NAME="docker_config"
RESOLV_CONF_NAME="resolv.conf"
HOST_CONFIG_DIR="$PWD/$CONFIG_DIR_NAME"
HOST_DNS_RESOLVER_FILE="$HOST_CONFIG_DIR/$RESOLV_CONF_NAME"
traffmonetizer_data_folder="traffmonetizerdata"
network3_data_folder="network3-data"
titan_data_folder="titan-data"
required_files=($banner_file $properties_file $firefox_profile_zipfile $restart_file $chrome_profile_zipfile)
files_to_be_removed=($containers_file $container_names_file $networks_file $mysterium_file $ebesucher_file $adnade_file $adnade_containers_file $firefox_containers_file $chrome_containers_file)
folders_to_be_removed=($adnade_data_folder $firefox_data_folder $firefox_profile_data $earnapp_data_folder $chrome_data_folder $chrome_profile_data meson_data $CONFIG_DIR_NAME)
back_up_folders=($titan_data_folder $network3_data_folder $bitping_data_folder $urnetwork_data_folder $traffmonetizer_data_folder $mysterium_data_folder meson_data)
back_up_files=($earnapp_file $proxybase_file $proxyrack_file)
container_pulled=false
docker_in_docker_detected=false

# Mysterium and ebesucher first port
mysterium_first_port=2000
ebesucher_first_port=3000
adnade_first_port=4000

#Unique Id
UNIQUE_ID=`cat /dev/urandom | LC_ALL=C tr -dc 'a-f0-9' | dd bs=1 count=32 2>/dev/null`

# Associative array for hypothetical daily earnings (in USD)
declare -A service_daily_earnings=(
  [Honeygain]=0.10
  [Peer2Profit]=0.08
  [PacketStream]=0.05
  [IPRoyal]=0.07
  [EarnApp]=0.12
  [Traffmonetizer]=0.06
  [Uprock]=0.09
  [MesonNetwork]=0.07
  [Repocket]=0.04      # Added Repocket as it's in properties
  [EarnFM]=0.03         # Added EarnFM
  [PacketSDK]=0.02      # Added PacketSDK
  [Gaganode]=0.01       # Added Gaganode
  [ProxyRack]=0.05      # Added ProxyRack
  [ProxyBase]=0.05      # Added ProxyBase
  [CastarSDK]=0.01      # Added CastarSDK
  [Wipter]=0.01         # Added Wipter
  [PacketShare]=0.02    # Added PacketShare
  [BitPing]=0.01        # Added BitPing
  [Grass]=0.03          # Added Grass (Depin)
  [Gradient]=0.02       # Added Gradient (Depin)
  [URNetwork]=0.01      # Added URNetwork
  [Network3]=0.01       # Added Network3
  [TitanNetwork]=0.01   # Added TitanNetwork
  [Mysterium]=0.04      # Added Mysterium
  [Ebesucher]=0.01      # Added Ebesucher
  [Adnade]=0.01         # Added Adnade
  [Proxylite]=0.01      # Added Proxylite
)

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

  local NORMALIZED_PWD="$PWD"
  # Remove trailing slashes if any, to prevent issues like //
  NORMALIZED_PWD=\${NORMALIZED_PWD%/}

  # Local, paths for resolv.conf, now using the cleaned NORMALIZED_PWD
  local LOCAL_HOST_CONFIG_DIR="$NORMALIZED_PWD/$CONFIG_DIR_NAME"
  local LOCAL_HOST_DNS_RESOLVER_FILE="$LOCAL_HOST_CONFIG_DIR/$RESOLV_CONF_NAME"
  # CLEANED_ versions are no longer needed as NORMALIZED_PWD is cleaned at source.

  # DNS_VOLUME will be inlined in each docker run command using LOCAL_HOST_DNS_RESOLVER_FILE
  local TUN_DNS_VOLUME

  if [ "$container_pulled" = false ]; then
    # For users with Docker-in-Docker, the PWD path is on the host where Docker is installed.
    # The files are created in the same path as the inner Docker path.
    mkdir -p "$LOCAL_HOST_CONFIG_DIR"
    printf 'nameserver 8.8.8.8\nnameserver 8.8.4.4\nnameserver 1.1.1.1\nnameserver 1.0.0.1\nnameserver 9.9.9.9\n' > "$LOCAL_HOST_DNS_RESOLVER_FILE";
    if [ ! -f "$LOCAL_HOST_DNS_RESOLVER_FILE" ]; then
      echo -e "${RED}There is a problem creating resolver file. Exiting..${NOCOLOUR}";
      exit 1;
    fi
    # These DinD checks use the original $PWD for the /output mount, which is fine as it's a broader scope.
    if sudo docker run --rm -v "$PWD:/output" docker:18.06.2-dind sh -c "if [ ! -f \"/output/$CONFIG_DIR_NAME/$RESOLV_CONF_NAME\" ]; then exit 0; else exit 1; fi"; then
      docker_in_docker_detected=true
    fi
    sudo docker run --rm -v "$PWD:/output" docker:18.06.2-dind sh -c "mkdir -p \"/output/$CONFIG_DIR_NAME\" && if [ ! -f \"/output/$CONFIG_DIR_NAME/$RESOLV_CONF_NAME\" ]; then printf 'nameserver 8.8.8.8\nnameserver 8.8.4.4\nnameserver 1.1.1.1\nnameserver 1.0.0.1\nnameserver 9.9.9.9\n' > \"/output/$CONFIG_DIR_NAME/$RESOLV_CONF_NAME\"; printf 'Docker-in-Docker is detected. The script runs with limited features.\nThe files and folders are created in the same path on the host where your parent docker is installed.\n'; fi"
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
      sudo docker pull xjasonlyu/tun2socks:v2.5.2
    fi
    if [ "$USE_SOCKS5_DNS" = true ]; then
      TUN_DNS_VOLUME="-v \"$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro\""
    elif [ "$USE_DNS_OVER_HTTPS" = true ]; then
      EXTRA_COMMANDS='echo -e "options use-vc\nnameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf;ip rule add iif lo ipproto udp dport 53 lookup main;'
    else
      TUN_DNS_VOLUME="-v \"$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro\""
      EXTRA_COMMANDS='ip rule add iif lo ipproto udp dport 53 lookup main;'
    fi
    if CONTAINER_ID=$(sudo docker run --name tun$UNIQUE_ID$i $LOGS_PARAM $TUN_DNS_VOLUME --restart=always -e LOGLEVEL=$TUN_LOG_PARAM -e PROXY=$proxy -e EXTRA_COMMANDS="$EXTRA_COMMANDS" -v '/dev/net/tun:/dev/net/tun' --cap-add=NET_ADMIN $combined_ports -d xjasonlyu/tun2socks:v2.5.2); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "tun$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for proxy. Exiting..${NOCOLOUR}"
      exit 1
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
    mkdir -p "$NORMALIZED_PWD/$mysterium_data_folder/node$i"
    sudo chmod -R 777 "$NORMALIZED_PWD/$mysterium_data_folder/node$i"
    if CONTAINER_ID=$(sudo docker run -d --name myst$UNIQUE_ID$i --cap-add=NET_ADMIN $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" -v "$NORMALIZED_PWD/$mysterium_data_folder/node$i:/var/lib/mysterium-node" --restart unless-stopped $myst_port mysteriumnetwork/myst:latest service --agreed-terms-and-conditions); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "myst$UNIQUE_ID$i" | tee -a $container_names_file
      echo "http://127.0.0.1:$mysterium_first_port" |tee -a $mysterium_file
      mysterium_first_port=`expr $mysterium_first_port + 1`
    else
      echo -e "${RED}Failed to start container for Mysterium. Exiting..${NOCOLOUR}"
      exit 1
    fi
  elif [[ "$MYSTERIUM" = true && $NETWORK_TUN ]]; then
    if [ "$container_pulled" = false ]; then
      echo -e "${RED}Proxy for Mysterium is not supported at the moment due to ongoing issue. Please see https://github.com/xjasonlyu/tun2socks/issues/262 for more details. Ignoring Mysterium..${NOCOLOUR}"
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Mysterium Node is not enabled. Ignoring Mysterium..${NOCOLOUR}"
    fi
  fi

  # Starting Meson Network container
  if [[ $MESON_TOKEN ]]; then
    echo -e "${GREEN}Starting Meson Network container...${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull mesonnetwork/meson-node:latest # Placeholder image, verify correct image
    fi
    mkdir -p "$NORMALIZED_PWD/meson_data/data$i"
    sudo chmod -R 777 "$NORMALIZED_PWD/meson_data/data$i"
    if CONTAINER_ID=$(sudo docker run -d --name meson$UNIQUE_ID$i --restart=always $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" -v "$NORMALIZED_PWD/meson_data/data$i:/opt/meson_data" -e MESON_TOKEN=$MESON_TOKEN mesonnetwork/meson-node:latest); then # Verify correct env var name
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "meson$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for Meson Network. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Meson Network Token is not configured. Ignoring Meson Network..${NOCOLOUR}"
    fi
  fi

  # Starting Uprock container
  if [[ $UPROCK_TOKEN ]]; then
    echo -e "${GREEN}Starting Uprock container...${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull uprock/client:latest # Placeholder image, verify correct image
    fi
    if CONTAINER_ID=$(sudo docker run -d --name uprock$UNIQUE_ID$i --restart=always $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" -e UPROCK_TOKEN=$UPROCK_TOKEN uprock/client:latest); then # Verify correct env var name
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "uprock$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for Uprock. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Uprock Token is not configured. Ignoring Uprock..${NOCOLOUR}"
    fi
  fi

  # Starting Ebesucher Chrome container
  if [[ $EBESUCHER_USERNAME && "$EBESUCHER_USE_CHROME" = true ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull lscr.io/linuxserver/chromium:latest

      # Exit, if chrome profile zip file is missing
      if [ ! -f "$NORMALIZED_PWD/$chrome_profile_zipfile" ];then
        echo -e "${RED}Chrome profile file does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi

      # Unzip the file
      unzip -o "$NORMALIZED_PWD/$chrome_profile_zipfile"

      # Exit, if chrome profile data is missing
      if [ ! -d "$NORMALIZED_PWD/$chrome_profile_data" ];then
        echo -e "${RED}Chrome Data folder does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi

    fi

    # Create folder and copy files
    mkdir -p "$NORMALIZED_PWD/$chrome_data_folder/data$i"
    sudo chown -R 911:911 "$NORMALIZED_PWD/$chrome_profile_data"
    sudo cp -r "$NORMALIZED_PWD/$chrome_profile_data" "$NORMALIZED_PWD/$chrome_data_folder/data$i"
    sudo chown -R 911:911 "$NORMALIZED_PWD/$chrome_data_folder/data$i"

    if [[ ! $proxy ]]; then
      ebesucher_first_port=$(check_open_ports $ebesucher_first_port 1)
      if ! expr "$ebesucher_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $ebesucher_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Ebesucher. Resolve or disable Ebesucher to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      eb_port="-p $ebesucher_first_port:3000 "
    fi

    if CONTAINER_ID=$(sudo docker run -d --name ebesucher$UNIQUE_ID$i $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" $NETWORK_TUN --security-opt seccomp=unconfined -e TZ=Etc/UTC -e CHROME_CLI="https://www.ebesucher.com/surfbar/$EBESUCHER_USERNAME" -v "$NORMALIZED_PWD/$chrome_data_folder/data$i/$chrome_profile_data:/config" --shm-size="1gb" $eb_port lscr.io/linuxserver/chromium:latest); then
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
    echo -e "${GREEN}Starting Ebesucher container..${NOCOLOUR}"
    echo -e "${GREEN}Copy the following node url and paste in your browser if required..${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $ebesucher_file in the same folder${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull jlesage/firefox

      # Exit, if firefox profile zip file is missing
      if [ ! -f "$NORMALIZED_PWD/$firefox_profile_zipfile" ];then
        echo -e "${RED}Firefox profile file does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi

      # Unzip the file
      unzip -o "$NORMALIZED_PWD/$firefox_profile_zipfile"

      # Exit, if firefox profile data is missing
      if [ ! -d "$NORMALIZED_PWD/$firefox_profile_data" ];then
        echo -e "${RED}Firefox Data folder does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi

    fi

    # Create folder and copy files
    mkdir -p "$NORMALIZED_PWD/$firefox_data_folder/data$i"
    sudo chmod -R 777 "$NORMALIZED_PWD/$firefox_profile_data"
    cp -r "$NORMALIZED_PWD/$firefox_profile_data/"* "$NORMALIZED_PWD/$firefox_data_folder/data$i/"
    sudo chmod -R 777 "$NORMALIZED_PWD/$firefox_data_folder/data$i"
    if [[ ! $proxy ]]; then
      ebesucher_first_port=$(check_open_ports $ebesucher_first_port 1)
      if ! expr "$ebesucher_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $ebesucher_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Ebesucher. Resolve or disable Ebesucher to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      eb_port="-p $ebesucher_first_port:5800"
    fi
    if CONTAINER_ID=$(sudo docker run -d --name ebesucher$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" --restart=always -e FF_OPEN_URL="https://www.ebesucher.com/surfbar/$EBESUCHER_USERNAME" -e VNC_LISTENING_PORT=-1 -v "$NORMALIZED_PWD/$firefox_data_folder/data$i:/config:rw" $eb_port jlesage/firefox); then
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
    echo -e "${GREEN}Starting Adnade container..${NOCOLOUR}"
    echo -e "${GREEN}Copy the following node url and paste in your browser if required..${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $adnade_file in the same folder${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull jlesage/firefox

      # Exit, if firefox profile zip file is missing
      if [ ! -f "$NORMALIZED_PWD/$firefox_profile_zipfile" ];then
        echo -e "${RED}Firefox profile file does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi

      # Unzip the file
      unzip -o "$NORMALIZED_PWD/$firefox_profile_zipfile"

      # Exit, if firefox profile data is missing
      if [ ! -d "$NORMALIZED_PWD/$firefox_profile_data" ];then
        echo -e "${RED}Firefox profile Data folder does not exist. Exiting..${NOCOLOUR}"
        exit 1
      fi

    fi

    # Create folder and copy files
    mkdir -p "$NORMALIZED_PWD/$adnade_data_folder/data$i"
    sudo chmod -R 777 "$NORMALIZED_PWD/$firefox_profile_data"
    cp -r "$NORMALIZED_PWD/$firefox_profile_data/"* "$NORMALIZED_PWD/$adnade_data_folder/data$i/"
    sudo chmod -R 777 "$NORMALIZED_PWD/$adnade_data_folder/data$i"
    if [[ ! $proxy ]]; then
      adnade_first_port=$(check_open_ports $adnade_first_port 1)
      if ! expr "$adnade_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $adnade_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Adnade. Resolve or disable Adnade to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      ad_port="-p $adnade_first_port:5900"
    fi
    if CONTAINER_ID=$(sudo docker run -d --name adnade$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" --restart=always -e FF_OPEN_URL="https://adnade.net/view.php?user=$ADNADE_USERNAME&multi=4" -e VNC_LISTENING_PORT=-1 -e WEB_LISTENING_PORT=5900 -v "$NORMALIZED_PWD/$adnade_data_folder/data$i:/config:rw" $ad_port jlesage/firefox); then
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
    mkdir -p "$NORMALIZED_PWD/$bitping_data_folder/data$i/.bitpingd"
    sudo chmod -R 777 "$NORMALIZED_PWD/$bitping_data_folder/data$i/.bitpingd"
    if [ ! -f "$NORMALIZED_PWD/$bitping_data_folder/data$i/.bitpingd/node.db" ]; then
        sudo docker run --rm $NETWORK_TUN -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" -v "$NORMALIZED_PWD/$bitping_data_folder/data$i/.bitpingd:/root/.bitpingd" --entrypoint /app/bitpingd bitping/bitpingd:latest login --email $BITPING_EMAIL --password $BITPING_PASSWORD
    fi
    if CONTAINER_ID=$(sudo docker run -d --name bitping$UNIQUE_ID$i --restart=always $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" -v "$NORMALIZED_PWD/$bitping_data_folder/data$i/.bitpingd:/root/.bitpingd" --entrypoint /app/bitpingd bitping/bitpingd:latest); then
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
    if CONTAINER_ID=$(sudo docker run -d --name repocket$UNIQUE_ID$i --restart=always $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" -e RP_EMAIL=$REPOCKET_EMAIL -e RP_API_KEY=$REPOCKET_API repocket/repocket); then
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

  # Starting Earn Fm container
  if [[ $EARN_FM_API ]]; then
    echo -e "${GREEN}Starting EarnFm container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull earnfm/earnfm-client:latest
    fi
    if CONTAINER_ID=$(sudo docker run -d --name earnfm$UNIQUE_ID$i --restart=always $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" -e EARNFM_TOKEN=$EARN_FM_API earnfm/earnfm-client:latest); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "earnfm$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for EarnFm. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}EarnFm Api is not configured. Ignoring EarnFm..${NOCOLOUR}"
    fi
  fi

  # Starting PacketSDK container
  if [[ $PACKET_SDK_APP_KEY ]]; then
    echo -e "${GREEN}Starting PacketSDK container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull packetsdk/packetsdk
    fi
    if CONTAINER_ID=$(sudo docker run -d --name packetsdk$UNIQUE_ID$i --restart=always $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" packetsdk/packetsdk -appkey=$PACKET_SDK_APP_KEY); then
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
    if CONTAINER_ID=$(sudo docker run -d --name gaganode$UNIQUE_ID$i --restart=always $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" -e TOKEN=$GAGANODE_TOKEN xterna/gaga-node); then
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
    mkdir -p "$NORMALIZED_PWD/$traffmonetizer_data_folder/data$i"
    sudo chmod -R 777 "$NORMALIZED_PWD/$traffmonetizer_data_folder/data$i"
    if CONTAINER_ID=$(sudo  docker run -d --name traffmon$UNIQUE_ID$i --restart=always $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" $NETWORK_TUN -v "$NORMALIZED_PWD/$traffmonetizer_data_folder/data$i:/app/traffmonetizer" $traffmonetizer_image start accept --device-name $DEVICE_NAME$i --token $TRAFFMONETIZER_TOKEN); then
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
  if [ "$PROXYRACK" = true ]; then
    echo -e "${GREEN}Starting Proxyrack container..${NOCOLOUR}"
    echo -e "${GREEN}Copy the following node uuid and paste in your proxyrack dashboard${NOCOLOUR}"
    echo -e "${GREEN}You will also find the uuids in the file $proxyrack_file in the same folder${NOCOLOUR}"
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

    if CONTAINER_ID=$(sudo docker run -d --name proxyrack$UNIQUE_ID$i --platform=linux/amd64 $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" --restart=always -e UUID=$proxyrack_uuid proxyrack/pop); then
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
  if [ "$PROXYBASE" = true ]; then
    echo -e "${GREEN}Starting Proxybase container..${NOCOLOUR}"
    echo -e "${GREEN}Copy the following node uuid and paste in your proxybase dashboard${NOCOLOUR}"
    echo -e "${GREEN}You will also find the uuids in the file $proxybase_file in the same folder${NOCOLOUR}"
    for loop_count in {1..500}; do
      if [ "$loop_count" -eq 500 ]; then
        echo -e "${RED}Unique UUID cannot be generated for ProxyBase. Exiting..${NOCOLOUR}"
        exit 1
      fi
      RANDOM_ID=`cat /dev/urandom | LC_ALL=C tr -dc 'a-f0-9' | dd bs=1 count=32 2>/dev/null`
      if [ -f $proxybase_file ]; then
        if ! grep -qF "$RANDOM_ID" "$proxybase_file"; then
          break
        fi
      else
        break;
      fi
    done
    if [ "$container_pulled" = false ]; then
      sudo docker pull proxybase/proxybase
    fi
    if [ -f $proxybase_file ] && proxybase_uuid=$(sed "${i}q;d" $proxybase_file);then
      if [[ $proxybase_uuid ]];then
        echo $proxybase_uuid
      else
        echo "Proxybase UUID does not exist, creating UUID"
        proxybase_uuid=$RANDOM_ID
        printf "%s\n" "$proxybase_uuid" | tee -a $proxybase_file
      fi
    else
      echo "Proxybase UUID does not exist, creating UUID"
      proxybase_uuid=$RANDOM_ID
      printf "%s\n" "$proxybase_uuid" | tee -a $proxybase_file
    fi

    if CONTAINER_ID=$(sudo docker run -d --name proxybase$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" --restart=always -e device_id=$proxybase_uuid proxybase/proxybase); then
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
    if CONTAINER_ID=$(sudo docker run -d --name pawns$UNIQUE_ID$i --restart=always $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" $NETWORK_TUN iproyal/pawns-cli:latest -email=$IPROYALS_EMAIL -password=$IPROYALS_PASSWORD -device-name=$DEVICE_NAME$i -device-id=$DEVICE_NAME$i -accept-tos); then
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
      sudo docker pull ghcr.io/adfly8470/castarsdk/castarsdk@sha256:881cdbe79f10dbfac65a1de0673587f67059b650f8cd94cd71801cc52a435f53
    fi
    if CONTAINER_ID=$(sudo docker run -d --name castarsdk$UNIQUE_ID$i --restart=always $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" -e KEY=$CASTAR_SDK_KEY ghcr.io/adfly8470/castarsdk/castarsdk@sha256:881cdbe79f10dbfac65a1de0673587f67059b650f8cd94cd71801cc52a435f53); then
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
      sudo docker pull --platform=linux/amd64 ghcr.io/adfly8470/wipter/wipter@sha256:339e6a23d6fd9a787fc35884b81d1dea9d169c40e902789ed73cb6b79621fba2
    fi
    if CONTAINER_ID=$(sudo docker run -d --platform=linux/amd64 --name wipter$UNIQUE_ID$i --restart=always $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" $NETWORK_TUN -e WIPTER_EMAIL=$WIPTER_EMAIL -e WIPTER_PASSWORD=$WIPTER_PASSWORD ghcr.io/adfly8470/wipter/wipter@sha256:339e6a23d6fd9a787fc35884b81d1dea9d169c40e902789ed73cb6b79621fba2); then
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
    if CONTAINER_ID=$(sudo docker run -d --name packetshare$UNIQUE_ID$i --restart=always $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" $NETWORK_TUN packetshare/packetshare -accept-tos -email=$PACKETSHARE_EMAIL -password=$PACKETSHARE_PASSWORD); then
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
    if CONTAINER_ID=$(sudo docker run -d --name depinext$UNIQUE_ID$i --restart=always $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" $NETWORK_TUN $grass_env $gradient_env carbon2029/dockweb); then
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
    if CONTAINER_ID=$(sudo docker run -d --name honey$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" --restart=always $honeygain_image -tou-accept -email $HONEYGAIN_EMAIL -pass $HONEYGAIN_PASSWORD -device $DEVICE_NAME$i); then
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
    if CONTAINER_ID=$(sudo docker run -d --platform=linux/amd64 --name peer2profit$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" --restart always -e email=$PEER2PROFIT_EMAIL enwaiax/peer2profit); then
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

  # Starting PacketStream container
  if [[ $PACKETSTREAM_CID ]]; then
    echo -e "${GREEN}Starting PacketStream container..${NOCOLOUR}"
    if [ "$container_pulled" = false ]; then
      sudo docker pull packetstream/psclient:latest
    fi
    if CONTAINER_ID=$(sudo docker run -d --name packetstream$UNIQUE_ID$i $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" --restart always -e HTTP_PROXY="" -e HTTPS_PROXY="" -e CID=$PACKETSTREAM_CID packetstream/psclient:latest); then
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
    if CONTAINER_ID=$(sudo docker run -d --name proxylite$UNIQUE_ID$i --platform=linux/amd64 $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro"  -e USER_ID=$PROXYLITE_USER_ID --restart=always proxylite/proxyservice); then
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
      mkdir -p "$NORMALIZED_PWD/$urnetwork_data_folder/data/.urnetwork"
      sudo chmod -R 777 "$NORMALIZED_PWD/$urnetwork_data_folder/data/.urnetwork"
      if [ ! -f "$NORMALIZED_PWD/$urnetwork_data_folder/data/.urnetwork/jwt" ]; then
        sudo docker run --rm $NETWORK_TUN -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" -v "$NORMALIZED_PWD/$urnetwork_data_folder/data/.urnetwork:/root/.urnetwork" --entrypoint /usr/local/sbin/bringyour-provider bringyour/community-provider:latest auth $UR_AUTH_TOKEN
        sleep 1
        if [ ! -f "$NORMALIZED_PWD/$urnetwork_data_folder/data/.urnetwork/jwt" ]; then
          echo -e "${RED}JWT file could not be generated for URnetwork. Exiting..${NOCOLOUR}"
          exit 1
        fi
      fi
    fi
    if CONTAINER_ID=$(sudo docker run -d --name urnetwork$UNIQUE_ID$i --restart=always $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" -v "$NORMALIZED_PWD/$urnetwork_data_folder/data/.urnetwork:/root/.urnetwork" bringyour/community-provider:latest provide); then
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

  # Starting Network3 container
  if [[ $NETWORK3_EMAIL ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull aron666/network3-ai
    fi
    mkdir -p "$NORMALIZED_PWD/$network3_data_folder/data$i"
    sudo chmod -R 777 "$NORMALIZED_PWD/$network3_data_folder/data$i"
    # DIAGNOSTIC: Temporarily removed --cap-add NET_ADMIN and --device /dev/net/tun for Network3 to debug 'custom device C' error.
    if CONTAINER_ID=$(sudo docker run -d --name network3$UNIQUE_ID$i --restart=always $NETWORK_TUN $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" -v "$NORMALIZED_PWD/$network3_data_folder/data$i:/usr/local/etc/wireguard" -e EMAIL=$NETWORK3_EMAIL aron666/network3-ai); then
      echo "$CONTAINER_ID" | tee -a $containers_file
      echo "network3$UNIQUE_ID$i" | tee -a $container_names_file
    else
      echo -e "${RED}Failed to start container for Network3. Exiting..${NOCOLOUR}"
      exit 1
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Network3 Email is not configured. Ignoring Network3..${NOCOLOUR}"
    fi
  fi

  # Starting Titan Network container
  if [[ $TITAN_HASH ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull nezha123/titan-edge
      mkdir -p "$NORMALIZED_PWD/$titan_data_folder/data$i"
      sudo chmod -R 777 "$NORMALIZED_PWD/$titan_data_folder/data$i"
      if CONTAINER_ID=$(sudo  docker run -d --name titan$UNIQUE_ID$i --restart=always $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" $NETWORK_TUN -v "$NORMALIZED_PWD/$titan_data_folder/data$i:/root/.titanedge" nezha123/titan-edge); then
        echo "$CONTAINER_ID" | tee -a $containers_file
        echo "titan$UNIQUE_ID$i" | tee -a $container_names_file
      else
        echo -e "${RED}Failed to start container for Titan Network. Exiting..${NOCOLOUR}"
        exit 1
      fi
      sleep 5
      sudo docker run --rm -it -v "$NORMALIZED_PWD/$titan_data_folder/data$i:/root/.titanedge" nezha123/titan-edge bind --hash=$TITAN_HASH https://api-test1.container1.titannet.io/api/v2/device/binding
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
    mkdir -p "$NORMALIZED_PWD/$earnapp_data_folder/data$i"
    sudo chmod -R 777 "$NORMALIZED_PWD/$earnapp_data_folder/data$i"
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

    if CONTAINER_ID=$(sudo docker run -d --health-interval=24h --name earnapp$UNIQUE_ID$i $LOGS_PARAM -v "$LOCAL_HOST_DNS_RESOLVER_FILE:/etc/resolv.conf:ro" --restart=always $NETWORK_TUN -v "$NORMALIZED_PWD/$earnapp_data_folder/data$i:/etc/earnapp" -e EARNAPP_UUID=$uuid fazalfarhan01/earnapp:lite); then
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
  done < <(grep -v -e '^UPROCK_TOKEN=' -e '^MESON_TOKEN=' "$properties_file"; grep -e '^UPROCK_TOKEN=' -e '^MESON_TOKEN=' "$properties_file")

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
    # For Docker-in-Docker
    sudo docker run --rm -v $PWD:/output docker:18.06.2-dind sh -c "if [ -f /output/$file ]; then rm /output/$file; fi"
  done

  # Delete folders
  for folder in "${folders_to_be_removed[@]}"; do
    if [ -d "$folder" ]; then
      rm -Rf $folder;
    fi
    # For Docker-in-Docker
    sudo docker run --rm -v $PWD:/output docker:18.06.2-dind sh -c "if [ -d /output/$folder ]; then rm -Rf /output/$folder; fi"
  done
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
    # For Docker-in-Docker
    sudo docker run --rm -v $PWD:/output docker:18.06.2-dind sh -c "if [ -f /output/$file ]; then rm /output/$file; fi"
  done

  # Delete backup folders
  for folder in "${back_up_folders[@]}"; do
    if [ -d "$folder" ]; then
      rm -Rf $folder;
    fi
    # For Docker-in-Docker
    sudo docker run --rm -v $PWD:/output docker:18.06.2-dind sh -c "if [ -d /output/$folder ]; then rm -Rf /output/$folder; fi"
  done
  exit 1
fi

# Estimate earnings
if [[ "$1" == "--estimate-earnings" ]]; then
  echo -e "\n\n${YELLOW}Calculating Estimated Earnings...${NOCOLOUR}"

  # Check if properties file exists
  if [ ! -f "$properties_file" ]; then
    echo -e "${RED}Properties file $properties_file does not exist. Cannot estimate earnings. Exiting..${NOCOLOUR}"
    exit 1
  fi

  # Remove special characters ^M from properties file
  sed -i 's/\r//g' $properties_file

  # Read the properties file and export variables to the current shell
  # This is a simplified version for checking if variables are set
  while IFS= read -r line; do
    if [[ $line != '#'* ]]; then
        key="${line%%=*}"
        value="${line#*=}"
        key="${key%"${key##*[![:space:]]}"}"
        value="${value%"${value##*[![:space:]]}"}"
        if [[ -n $value ]]; then
            # For estimation, we just need to know if the credential is set
            export "$key"="$value"
        fi
    fi
  done < <(grep -v -E '^(UPROCK_TOKEN|MESON_TOKEN)=' "$properties_file"; grep -E '^(UPROCK_TOKEN|MESON_TOKEN)=' "$properties_file")


  total_daily_estimate=0.0
  echo -e "\n${GREEN}Estimated Daily Earnings per Service (USD):${NOCOLOUR}"

  if [[ -n "$HONEYGAIN_EMAIL" && -n "$HONEYGAIN_PASSWORD" ]]; then
    echo "  - Honeygain: \$${service_daily_earnings[Honeygain]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[Honeygain]}" | bc)
  fi
  if [[ -n "$PEER2PROFIT_EMAIL" ]]; then
    echo "  - Peer2Profit: \$${service_daily_earnings[Peer2Profit]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[Peer2Profit]}" | bc)
  fi
  if [[ -n "$PACKETSTREAM_CID" ]]; then
    echo "  - PacketStream: \$${service_daily_earnings[PacketStream]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[PacketStream]}" | bc)
  fi
  if [[ -n "$IPROYALS_EMAIL" && -n "$IPROYALS_PASSWORD" ]]; then
    echo "  - IPRoyal Pawns: \$${service_daily_earnings[IPRoyal]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[IPRoyal]}" | bc)
  fi
  if [[ "$EARNAPP" == true ]]; then
    echo "  - EarnApp: \$${service_daily_earnings[EarnApp]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[EarnApp]}" | bc)
  fi
  if [[ -n "$TRAFFMONETIZER_TOKEN" ]]; then
    echo "  - Traffmonetizer: \$${service_daily_earnings[Traffmonetizer]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[Traffmonetizer]}" | bc)
  fi
  if [[ -n "$UPROCK_TOKEN" ]]; then
    echo "  - Uprock: \$${service_daily_earnings[Uprock]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[Uprock]}" | bc)
  fi
  if [[ -n "$MESON_TOKEN" ]]; then
    echo "  - Meson Network: \$${service_daily_earnings[MesonNetwork]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[MesonNetwork]}" | bc)
  fi
  if [[ -n "$REPOCKET_EMAIL" && -n "$REPOCKET_API" ]]; then
    echo "  - Repocket: \$${service_daily_earnings[Repocket]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[Repocket]}" | bc)
  fi
  if [[ -n "$EARN_FM_API" ]]; then
    echo "  - EarnFM: \$${service_daily_earnings[EarnFM]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[EarnFM]}" | bc)
  fi
  if [[ -n "$PACKET_SDK_APP_KEY" ]]; then
    echo "  - PacketSDK: \$${service_daily_earnings[PacketSDK]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[PacketSDK]}" | bc)
  fi
  if [[ -n "$GAGANODE_TOKEN" ]]; then
    echo "  - Gaganode: \$${service_daily_earnings[Gaganode]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[Gaganode]}" | bc)
  fi
  if [[ "$PROXYRACK" == true ]]; then
    echo "  - ProxyRack: \$${service_daily_earnings[ProxyRack]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[ProxyRack]}" | bc)
  fi
  if [[ "$PROXYBASE" == true ]]; then
    echo "  - ProxyBase: \$${service_daily_earnings[ProxyBase]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[ProxyBase]}" | bc)
  fi
  if [[ -n "$CASTAR_SDK_KEY" ]]; then
    echo "  - CastarSDK: \$${service_daily_earnings[CastarSDK]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[CastarSDK]}" | bc)
  fi
  if [[ -n "$WIPTER_EMAIL" && -n "$WIPTER_PASSWORD" ]]; then
    echo "  - Wipter: \$${service_daily_earnings[Wipter]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[Wipter]}" | bc)
  fi
  if [[ -n "$PACKETSHARE_EMAIL" && -n "$PACKETSHARE_PASSWORD" ]]; then
    echo "  - PacketShare: \$${service_daily_earnings[PacketShare]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[PacketShare]}" | bc)
  fi
  if [[ -n "$BITPING_EMAIL" && -n "$BITPING_PASSWORD" ]]; then
    echo "  - BitPing: \$${service_daily_earnings[BitPing]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[BitPing]}" | bc)
  fi
  if [[ -n "$GRASS_EMAIL" && -n "$GRASS_PASSWORD" ]]; then # Assuming GRASS is one of the depin
    echo "  - Grass: \$${service_daily_earnings[Grass]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[Grass]}" | bc)
  fi
  if [[ -n "$GRADIENT_EMAIL" && -n "$GRADIENT_PASSWORD" ]]; then # Assuming GRADIENT is one of the depin
    echo "  - Gradient Network: \$${service_daily_earnings[Gradient]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[Gradient]}" | bc)
  fi
   if [[ -n "$UR_AUTH_TOKEN" ]]; then
    echo "  - URNetwork: \$${service_daily_earnings[URNetwork]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[URNetwork]}" | bc)
  fi
  if [[ -n "$NETWORK3_EMAIL" ]]; then
    echo "  - Network3 AI: \$${service_daily_earnings[Network3]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[Network3]}" | bc)
  fi
  if [[ -n "$TITAN_HASH" ]]; then
    echo "  - Titan Network: \$${service_daily_earnings[TitanNetwork]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[TitanNetwork]}" | bc)
  fi
  if [[ "$MYSTERIUM" == true ]]; then
    echo "  - Mysterium: \$${service_daily_earnings[Mysterium]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[Mysterium]}" | bc)
  fi
  if [[ -n "$EBESUCHER_USERNAME" ]]; then
    echo "  - Ebesucher: \$${service_daily_earnings[Ebesucher]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[Ebesucher]}" | bc)
  fi
  if [[ -n "$ADNADE_USERNAME" ]]; then
    echo "  - Adnade: \$${service_daily_earnings[Adnade]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[Adnade]}" | bc)
  fi
  if [[ -n "$PROXYLITE_USER_ID" ]]; then
    echo "  - Proxylite: \$${service_daily_earnings[Proxylite]}"
    total_daily_estimate=$(echo "$total_daily_estimate + ${service_daily_earnings[Proxylite]}" | bc)
  fi

  echo -e "\n${GREEN}Total Estimated Daily Earnings: \$${total_daily_estimate}${NOCOLOUR}"
  total_monthly_estimate=$(echo "$total_daily_estimate * 30" | bc)
  echo -e "${GREEN}Total Estimated Monthly Earnings (30 days): \$${total_monthly_estimate}${NOCOLOUR}"

  echo -e "\n${RED}DISCLAIMER: These are rough estimates based on hypothetical average earnings. Actual earnings can vary significantly based on demand, location, network performance, number of IPs/proxies used, and other factors. This tool is for illustrative purposes only.${NOCOLOUR}"
  exit 0 # Exit after displaying estimates
fi

# Display status of containers
if [[ "$1" == "--status" ]]; then
  echo -e "\n${YELLOW}Status of Internet Income Containers:${NOCOLOUR}"
  if [ ! -f "$container_names_file" ]; then
    echo -e "${RED}No container information file found ($container_names_file). Either no containers were started by this script, or the file is missing.${NOCOLOUR}"
    exit 1
  fi

  if [ ! -s "$container_names_file" ]; then # Check if file is empty
    echo -e "${YELLOW}Container information file ($container_names_file) is empty. No active containers managed by this script.${NOCOLOUR}"
    exit 0
  fi

  while IFS= read -r container_name || [ -n "$container_name" ]; do
    if [ -z "$container_name" ]; then # Skip empty lines
      continue
    fi
    # Exact match for container name using ^ and $
    status_output=$(sudo docker ps -a --filter name=^"$container_name"$ --format "{{.Names}}: {{.Status}} (State: {{.State}})")
    if [ -z "$status_output" ]; then
      echo -e "${GREEN}$container_name${NOCOLOUR}: ${RED}Not found by Docker (may have been manually removed or script is run by non-root user without sudo privileges).${NOCOLOUR}"
    else
      echo -e "${GREEN}${status_output}${NOCOLOUR}"
    fi
  done < "$container_names_file"
  exit 0
fi

echo -e "Valid options are: ${RED}--start${NOCOLOUR}, ${RED}--delete${NOCOLOUR}, ${RED}--deleteBackup${NOCOLOUR}, ${RED}--estimate-earnings${NOCOLOUR}, ${RED}--status${NOCOLOUR}"
