#!/bin/bash

##################################################################################
# Author: engageub                                                               #
# Description: This script lets you earn passive income by sharing your internet #
# connection. It also supports multiple proxies, multiple IPs and multiple VPNs. #
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
multi_ip_file="multi_ips.txt"
container_names_file="containernames.txt"
subnets_file="subnets.txt"
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
uprock_file="uprock.txt"
firefox_containers_file="firefoxcontainers.txt"
chrome_containers_file="chromecontainers.txt"
adnade_containers_file="adnadecontainers.txt"
bitping_data_folder="bitping-data"
urnetwork_data_folder="urnetwork-data"
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
titan_data_folder="titan-data"
proxyrack_file="proxyrack.txt"
cloudflare_file="cloudflared"
dns_resolver_file="resolv.conf"
earn_fm_config_file="earnfm_config.json"
connection_state_file="connection_state.txt"
ur_proxies_file="ur_proxies.txt"
ur_data_proxies_file="$urnetwork_data_folder/data/.urnetwork/proxy"
process_id_file="process.pid"
required_files=($banner_file $properties_file $firefox_profile_zipfile $restart_file $generate_device_ids_file)
files_to_be_removed=($dns_resolver_file $cloudflare_file $container_names_file $subnets_file $networks_file $mysterium_file $ebesucher_file $adnade_file $firefox_containers_file $chrome_containers_file $adnade_containers_file $custom_chrome_file $custom_firefox_file $uprock_file $earn_fm_config_file $connection_state_file $ur_proxies_file $ur_data_proxies_file $process_id_file)
folders_to_be_removed=($firefox_data_folder $firefox_profile_data $adnade_data_folder $chrome_data_folder $chrome_profile_data $earnapp_data_folder)
back_up_folders=($titan_data_folder $bitping_data_folder $urnetwork_data_folder $traffmonetizer_data_folder $mysterium_data_folder $custom_chrome_data_folder $custom_firefox_data_folder)
back_up_files=($proxyrack_file $earnapp_file)
restricted_ports=(1 7 9 11 13 15 17 19 20 21 22 23 25 37 42 43 53 69 77 79 87 95 101 102 103 104 109 110 111 113 115 117 119 123 135 137 139 143 161 179 389 427 465 512 513 514 515 526 530 531 532 540 548 554 556 563 587 601 636 993 995 1719 1720 1723 2049 3659 4045 5060 5061 6000 6566 6665 6666 6667 6668 6669 6697 10080)
container_pulled=false
docker_in_docker_detected=false

# WatchTower container name
WATCH_TOWER_NAME="internetincomewatchtower"

# Mysterium and ebesucher first port
mysterium_first_port=2000
ebesucher_first_port=3000
adnade_first_port=4000
uprock_first_port=6100
custom_firefox_first_port=5000
custom_chrome_first_port=7000

# Initial Octet for multi IP
first_octet=192
second_octet=168
third_octet=32

# Unique ID
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
  if [ "$GENERATE_DEVICE_ID" = true ]; then
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
    if command -v lsof &>/dev/null; then
      sudo lsof -i :$port_to_check >/dev/null 2>&1
    elif [ -e /dev/tcp/localhost ]; then
      { timeout 1 bash -c "echo > /dev/tcp/localhost/$port_to_check" > /dev/null; } 2>/dev/null
    else
      nc -z localhost $port_to_check  > /dev/null 2>&1
    fi
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

# Check if a subnet is in use
is_subnet_in_use() {
  local subnet=$1
  local tables=("filter" "nat" "mangle" "raw" "security")

  # Iterate over each table and check for the subnet
  for table in "${tables[@]}"; do
    if sudo iptables -t "$table" -L -v -n 2>/dev/null | grep -q "$subnet"; then
      return 0  # Subnet is in use
    fi
  done

  return 1  # Subnet is not in use
}

# Find the next available subnet
find_next_available_subnet() {
  while true; do

    # Increment the third octet, and handle overflow
    ((third_octet++))
    if [ $third_octet -gt 255 ]; then
      third_octet=0
      ((second_octet++))
    fi

    # Increment the second octet, and handle overflow
    if [ $second_octet -gt 255 ]; then
      second_octet=0
      ((first_octet++))
    fi

    # Handle overflow for first octet
    if [ $first_octet -gt 255 ]; then
      echo "Exceeded IP address range"
      exit 1
    fi

    next_subnet="$first_octet.$second_octet.$third_octet.0/24"
    if ! is_subnet_in_use "$next_subnet"; then
      echo "$next_subnet"
      return 0
    fi
  done
}

# Execute docker command
execute_docker_command() {
  # Store parameters as an array
  local container_parameters=("$@")
  local app_name=${container_parameters[0]}
  local container_name=${container_parameters[1]}
  local CONTAINER_ID
  local DOCKER_INIT
  local WATCH_TOWER_LABEL
  if [[ "$USE_DOCKER_INIT" = true ]]; then
    DOCKER_INIT="--init"
  fi
  
  # Enable Watchtower auto-update for containers using the ':latest' tag,
  # but skip Watchtower itself to avoid recursive self-updating.
  if [[ "$AUTO_UPDATE_CONTAINERS" == true && "${container_parameters[@]:2}" == *":latest"* && "$container_name" != "$WATCH_TOWER_NAME" ]]; then
    WATCH_TOWER_LABEL='--label=com.centurylinklabs.watchtower.enable=true'
  fi
  
  echo -e "${YELLOW}Starting $app_name container..${NOCOLOUR}"
  # Check if container exists
  if sudo docker inspect $container_name >/dev/null 2>&1; then
    echo -e "${RED}A container with name $container_name already exists..${NOCOLOUR}"
    echo -e "${RED}Failed to start container for $app_name..Exiting..${NOCOLOUR}"
    exit 1
  else
    echo "$container_name" | tee -a "$container_names_file"
  fi

  if [[ "$app_name" == "VPN" ]]; then
    CONTAINER_ID=$(eval "sudo docker run $DOCKER_INIT -d --name $container_name --restart=always ${container_parameters[@]:2}")
  else
    CONTAINER_ID=$(sudo docker run $DOCKER_INIT -d $WATCH_TOWER_LABEL --name $container_name --restart=always "${container_parameters[@]:2}")
  fi

  # Check if the container started successfully
  if [[ -n "$CONTAINER_ID" ]]; then
    echo -e "${GREEN}Container $container_name started successfully.${NOCOLOUR}"
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

  local i=$1
  local proxy=$2
  local vpn_enabled=$3
  local NETWORK_TUN
  local localhost_address="127.0.0.1"
  local local_IP_address
  local DNS_VOLUME="--mount type=bind,source=$PWD/$dns_resolver_file,target=/etc/resolv.conf,readonly"
  local TUN_DNS_VOLUME

  if [[ "$USE_DOCKER_EMBEDDED_DNS" = true ]]; then
    DNS_VOLUME="";
  fi

   if [[ "$container_pulled" = false && "$START_ONLY" != true ]]; then

    # For users with Docker-in-Docker, the PWD path is on the host where Docker is installed.
    # The files are created in the same path as the inner Docker path.
    printf 'nameserver 8.8.8.8\nnameserver 8.8.4.4\nnameserver 1.1.1.1\nnameserver 1.0.0.1\n' > $dns_resolver_file;
    if [ ! -f $dns_resolver_file ]; then
      echo -e "${RED}There is a problem creating resolver file. Exiting..${NOCOLOUR}";
      exit 1;
    fi
    if sudo docker run --rm -v "$PWD:/output" docker:18.06.2-dind sh -c "if [ ! -f /output/$dns_resolver_file ]; then exit 0; else exit 1; fi"; then
      docker_in_docker_detected=true
    fi
    sudo docker run --rm -v $PWD:/output docker:18.06.2-dind sh -c "if [ ! -f /output/$dns_resolver_file ]; then printf 'nameserver 8.8.8.8\nnameserver 8.8.4.4\nnameserver 1.1.1.1\nnameserver 1.0.0.1\n' > /output/$dns_resolver_file; printf 'Docker-in-Docker is detected. The script runs with limited features.\nThe files and folders are created in the same path on the host where your parent docker is installed.\n'; fi"
  fi

  if [[ "$ENABLE_LOGS" != true ]]; then
    LOGS_PARAM="--log-driver none"
    TUN_LOG_PARAM="silent"
  else
    LOGS_PARAM="--log-driver=json-file --log-opt max-size=100k"
    TUN_LOG_PARAM="debug"
  fi

  if [[ $MAX_MEMORY ]]; then
    MAX_MEMORY_PARAM="-m $MAX_MEMORY"
  fi

  if [[ $MEMORY_RESERVATION ]]; then
    MEMORY_RESERVATION_PARAM="--memory-reservation=$MEMORY_RESERVATION"
  fi

  if [[ $MEMORY_SWAP ]]; then
    MEMORY_SWAP_PARAM="--memory-swap=$MEMORY_SWAP"
  fi

  if [[ $CPU ]]; then
    CPU_PARAM="--cpus=$CPU"
  fi

  if [[ $i && $proxy && "$START_ONLY" != true ]]; then
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

    if [ "$UPROCK" = true ]; then
      uprock_first_port=$(check_open_ports $uprock_first_port)
      if ! expr "$uprock_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $uprock_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Uprock. Resolve or disable Uprock to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      uprock_port="-p $uprock_first_port:5111 "
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

    if [[ $WIPTER_EMAIL && $WIPTER_PASSWORD ]]; then
      HOST_NAME="--hostname $DEVICE_NAME$i"
    fi

    combined_ports=$mysterium_port$ebesucher_port$adnade_port$custom_firefox_port$custom_chrome_port$uprock_port

    if [ "$vpn_enabled" = true ];then
      # Starting vpn containers
      if [ "$container_pulled" = false ]; then
        sudo docker pull qmcgaw/gluetun:v3.37.0
      fi
      if  [ "$USE_DNS_OVER_HTTPS" = true ]; then
         dns_option="-e DOT=on"
      else
         dns_option="-e DOT=off"
      fi
      NETWORK_TUN="--network=container:gluetun$UNIQUE_ID$i"
      docker_parameters=($HOST_NAME $LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM  $proxy -e BLOCK_MALICIOUS=off $dns_option --device /dev/net/tun --cap-add=NET_ADMIN $combined_ports --no-healthcheck qmcgaw/gluetun:v3.37.0)
      execute_docker_command "VPN" "gluetun$UNIQUE_ID$i" "${docker_parameters[@]}"
    elif [ "$vpn_enabled" = false ];then
      NETWORK_TUN="--network=multi$UNIQUE_ID$i"
      new_subnet=$(find_next_available_subnet)
      if NETWORK_ID=$(sudo docker network create multi$UNIQUE_ID$i --driver bridge --subnet $new_subnet); then
        echo "multi$UNIQUE_ID$i" | tee -a $networks_file
        if sudo iptables -t nat -I POSTROUTING -s $new_subnet -j SNAT --to-source $proxy; then
          echo "$new_subnet" "$proxy" | tee -a $subnets_file
        else
          echo "${RED}The iptables command failed..Exiting..${NOCOLOUR}"
          exit 1
        fi
      else
        echo -e "${RED}Failed to create network multi$UNIQUE_ID$i..Exiting..${NOCOLOUR}"
        exit 1
      fi
    elif [ "$USE_TUN2PROXY" = true ];then
      # Starting tun2proxy containers
      if [ "$container_pulled" = false ]; then
        sudo docker pull ghcr.io/tun2proxy/tun2proxy:v0.7.19
      fi
      if [[ "$ENABLE_LOGS" != true ]]; then
        TUN_LOG_PARAM="off"
      else
        TUN_LOG_PARAM="trace"
      fi
      if [ "$USE_SOCKS5_DNS" = true ]; then
         dns_option="--dns direct"
      elif  [ "$USE_DNS_OVER_HTTPS" = true ]; then
         dns_option="--dns over-tcp"
      else
         dns_option="--dns virtual"
      fi
      if [ "$USE_CUSTOM_NETWORK" = true ] && { [ "$i" -eq 1 ] || [ "$((i % 1000))" -eq 0 ]; }; then
        echo -e "${GREEN}Creating new network..${NOCOLOUR}"
        network_name="net$UNIQUE_ID$i"
        CUSTOM_NETWORK="--network=$network_name"
        if NETWORK_ID=$(sudo docker network create $network_name); then
          echo "$network_name" | tee -a $networks_file
        else
          echo -e "${RED}Failed to create network $network_name..Exiting..${NOCOLOUR}"
          exit 1
        fi
      fi
      docker_parameters=($HOST_NAME $LOGS_PARAM $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $CUSTOM_NETWORK --sysctl net.ipv6.conf.default.disable_ipv6=0 --device /dev/net/tun --cap-add=NET_ADMIN $combined_ports -d ghcr.io/tun2proxy/tun2proxy:v0.7.19 $dns_option --proxy $proxy --verbosity $TUN_LOG_PARAM)
      execute_docker_command "Proxy" "tun$UNIQUE_ID$i" "${docker_parameters[@]}"
    else
      # Starting tun2socks containers
      if [ "$container_pulled" = false ]; then
        if [ "$USE_SOCKS5_DNS" = true ]; then
          sudo docker pull ghcr.io/heiher/hev-socks5-tunnel:2.14.3
        else
          sudo docker pull xjasonlyu/tun2socks:v2.6.0
        fi
      fi
      if [ "$USE_SOCKS5_DNS" = true ]; then
        TUN_DNS_VOLUME="$DNS_VOLUME"
      elif [ "$USE_DNS_OVER_HTTPS" = true ]; then

        # Set the download URL based on the architecture
        case "$CPU_ARCH" in
          x86_64 | amd64)
            CF_URL="https://github.com/cloudflare/cloudflared/releases/download/2025.11.1/cloudflared-linux-amd64"
            ;;
          i686 | i386)
            CF_URL="https://github.com/cloudflare/cloudflared/releases/download/2025.11.1/cloudflared-linux-386"
            ;;
          armv7l | armv6l | armhf)
            CF_URL="https://github.com/cloudflare/cloudflared/releases/download/2025.11.1/cloudflared-linux-arm"
            ;;
          arm64 | aarch64)
            CF_URL="https://github.com/cloudflare/cloudflared/releases/download/2025.11.1/cloudflared-linux-arm64"
            ;;
          *)
            echo -e "${RED}Unsupported architecture: $CPU_ARCH. Please disable DNS over HTTPS if the problem persists. Exiting..${NOCOLOUR}"
            exit 1
            ;;
        esac

        wget -O cloudflared $CF_URL

        if [ ! -f cloudflared ]; then
          echo -e "${RED}There is a problem downloading cloudflared. Please disable DNS over HTTPS if the problem persists. Exiting..${NOCOLOUR}"
          exit 1;
        fi
        sudo chmod 777 cloudflared
        cloudflare_volume="-v $PWD/cloudflared:/cloudflare/cloudflared"
        EXTRA_COMMANDS='iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:53;iptables -t nat -A OUTPUT -p udp --dport 53 -j DNAT --to-destination 127.0.0.1:53;echo "nameserver 127.0.0.1" > /etc/resolv.conf; chmod +x /cloudflare/cloudflared;/cloudflare/cloudflared proxy-dns --upstream "https://8.8.8.8/dns-query" --upstream "https://8.8.4.4/dns-query" --upstream "https://1.1.1.1/dns-query" --upstream "https://1.0.0.1/dns-query" --max-upstream-conns 0 &'
      else
        TUN_DNS_VOLUME="$DNS_VOLUME"
        EXTRA_COMMANDS='ip rule add iif lo ipproto udp dport 53 lookup main;'
      fi
      if [ "$USE_CUSTOM_NETWORK" = true ] && { [ "$i" -eq 1 ] || [ "$((i % 1000))" -eq 0 ]; }; then
        echo -e "${GREEN}Creating new network..${NOCOLOUR}"
        network_name="net$UNIQUE_ID$i"
        CUSTOM_NETWORK="--network=$network_name"
        if NETWORK_ID=$(sudo docker network create $network_name); then
          echo "$network_name" | tee -a $networks_file
        else
          echo -e "${RED}Failed to create network $network_name..Exiting..${NOCOLOUR}"
          exit 1
        fi
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
        docker_parameters=($HOST_NAME $LOGS_PARAM $TUN_DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $CUSTOM_NETWORK -e LOG_LEVEL=$TUN_LOG_PARAM -v '/dev/net/tun:/dev/net/tun' --cap-add=NET_ADMIN $combined_ports -e SOCKS5_ADDR="$SOCKS_ADDR" -e SOCKS5_PORT="$SOCKS_PORT" -e SOCKS5_USERNAME="$SOCKS_USER" -e SOCKS5_PASSWORD="$SOCKS_PASS" --no-healthcheck ghcr.io/heiher/hev-socks5-tunnel:2.14.3)
        execute_docker_command "Proxy" "tun$UNIQUE_ID$i" "${docker_parameters[@]}"
      else
        docker_parameters=($HOST_NAME $LOGS_PARAM $TUN_DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $CUSTOM_NETWORK -e LOGLEVEL=$TUN_LOG_PARAM -e PROXY=$proxy -e EXTRA_COMMANDS="$EXTRA_COMMANDS" --device /dev/net/tun $cloudflare_volume --cap-add=NET_ADMIN $combined_ports xjasonlyu/tun2socks:v2.6.0)
        execute_docker_command "Proxy" "tun$UNIQUE_ID$i" "${docker_parameters[@]}"
      fi
    fi
  fi
  
  if [ "$START_ONLY" = true ]; then
    if [ "$vpn_enabled" = true ];then
      NETWORK_TUN="--network=container:gluetun$UNIQUE_ID$i"
    elif [ "$vpn_enabled" = false ];then
      NETWORK_TUN="--network=multi$UNIQUE_ID$i"
    elif [ $proxy ]; then
      NETWORK_TUN="--network=container:tun$UNIQUE_ID$i"
    else
      NETWORK_TUN=""
    fi
  fi

  # Assign IP address for multi IP
  if [[ $NETWORK_TUN == "--network=multi"* ]]; then
    local_IP_address="$proxy"
    localhost_address="$proxy"
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
      myst_port="-p $local_IP_address:$mysterium_first_port:4449"
    fi
    mkdir -p $PWD/$mysterium_data_folder/node$i
    sudo chmod -R 777 $PWD/$mysterium_data_folder/node$i
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM --cap-add=NET_ADMIN $NETWORK_TUN -v $PWD/$mysterium_data_folder/node$i:/var/lib/mysterium-node $myst_port mysteriumnetwork/myst:latest service --agreed-terms-and-conditions)
    execute_docker_command "Mysterium" "myst$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the following node url and paste in your browser${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $mysterium_file in the same folder${NOCOLOUR}"
    echo "http://$localhost_address:$mysterium_first_port" |tee -a $mysterium_file
    mysterium_first_port=`expr $mysterium_first_port + 1`
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Mysterium Node is not enabled. Ignoring Mysterium..${NOCOLOUR}"
    fi
  fi

  # Starting Uprock container
  if [ "$UPROCK" = true ]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull --platform=linux/amd64 ghcr.io/bhavishyadahiya/uprock-docker/uprock@sha256:e31e5bd0ce46884ddef1a90ed743d278096f4249e8ca1cd835159638cc23b17c
    fi
    if [[ ! $proxy ]] || [ "$vpn_enabled" = false ]; then
      uprock_first_port=$(check_open_ports $uprock_first_port)
      if ! expr "$uprock_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $uprock_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Uprock. Resolve or disable Uprock to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      uprock_container_port="-p $local_IP_address:$uprock_first_port:5111"
    fi
    docker_parameters=(--platform=linux/amd64 $LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN $uprock_container_port -e VNC_PORT=5722 -e WEBSOCKIFY_PORT=5111 -e VNC_PASSWORD="internetincome" ghcr.io/bhavishyadahiya/uprock-docker/uprock@sha256:e31e5bd0ce46884ddef1a90ed743d278096f4249e8ca1cd835159638cc23b17c)
    execute_docker_command "Uprock" "uprock$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the following node url and paste in your browser${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $uprock_file in the same folder${NOCOLOUR}"
    echo "http://$localhost_address:$uprock_first_port" |tee -a $uprock_file
    uprock_first_port=`expr $uprock_first_port + 1`
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Uprock is not enabled. Ignoring Uprock..${NOCOLOUR}"
    fi
  fi


  # Starting Custom Firefox container
  if [[ "$CUSTOM_FIREFOX" = true  ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull jlesage/firefox:latest
    fi

    if [[ ! $proxy ]] || [ "$vpn_enabled" = false ]; then
      custom_firefox_first_port=$(check_open_ports $custom_firefox_first_port)
      if ! expr "$custom_firefox_first_port" : '[[:digit:]]*$' >/dev/null; then
         echo -e "${RED}Problem assigning port $custom_firefox_first_port ..${NOCOLOUR}"
         echo -e "${RED}Failed to start Custom Firefox. Resolve or disable Custom Firefox to continue. Exiting..${NOCOLOUR}"
         exit 1
      fi
      cf_port="-p $local_IP_address:$custom_firefox_first_port:5911"
    fi

    # Setting random window height and width for firefox
    if [ "$CUSTOM_FIREFOX_USE_RANDOM_DISPLAY" = true ]; then
      MIN_WIDTH=1280
      MIN_HEIGHT=1024
      WINDOW_WIDTH=$((RANDOM % (1920 - MIN_WIDTH + 1) + MIN_WIDTH))
      WINDOW_HEIGHT=$((RANDOM % (1080 - MIN_HEIGHT + 1) + MIN_HEIGHT))
      CUSTOM_FIREFOX_DISPLAY_PARAMETERS="-e DISPLAY_WIDTH=$WINDOW_WIDTH  -e DISPLAY_HEIGHT=$WINDOW_HEIGHT"
    fi

    mkdir -p $PWD/$custom_firefox_data_folder/data$i
    sudo chmod -R 777 $PWD/$custom_firefox_data_folder/data$i
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -e KEEP_APP_RUNNING=1 $CUSTOM_FIREFOX_DISPLAY_PARAMETERS -e VNC_LISTENING_PORT=-1 -e WEB_LISTENING_PORT=5911 -e VNC_PASSWORD="internetincome" $cf_port -v $PWD/$custom_firefox_data_folder/data$i:/config:rw jlesage/firefox:latest)
    execute_docker_command "Custom Firefox" "customfirefox$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the following node url and paste in your browser if required..${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $custom_firefox_file in the same folder${NOCOLOUR}"
    echo "http://$localhost_address:$custom_firefox_first_port" |tee -a $custom_firefox_file
    custom_firefox_first_port=`expr $custom_firefox_first_port + 1`
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
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
      cc_port="-p $local_IP_address:$custom_chrome_first_port:3200 "
    fi

    mkdir -p $PWD/$custom_chrome_data_folder/data$i
    sudo chown -R 911:911 $PWD/$custom_chrome_data_folder/data$i
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN --security-opt seccomp=unconfined -e TZ=Etc/UTC   -e CUSTOM_HTTPS_PORT=3201 -e CUSTOM_PORT=3200 -e CUSTOM_USER="internetincome" -e PASSWORD="internetincome" --shm-size="1gb" $cc_port -v $PWD/$custom_chrome_data_folder/data$i:/config lscr.io/linuxserver/chromium:latest)
    execute_docker_command "Custom Chrome" "customchrome$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the following node url and paste in your browser if required..${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $custom_chrome_file in the same folder${NOCOLOUR}"
    echo "http://$localhost_address:$custom_chrome_first_port" |tee -a $custom_chrome_file
    custom_chrome_first_port=`expr $custom_chrome_first_port + 1`
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Custom chrome is not configured. Ignoring Custom Chrome..${NOCOLOUR}"
    fi
  fi

  # Starting Ebesucher Firefox container
  if [[ $EBESUCHER_USERNAME && "$EBESUCHER_USE_CHROME" != true  ]]; then
    if [ "$docker_in_docker_detected" = true ]; then
      echo -e "${RED}Adnade and Ebesucher are not supported now in Docker-in-Docker. Kindly use custom chrome or custom firefox and login manually. Exiting..${NOCOLOUR}";
      exit 1
    fi
    if [ "$container_pulled" = false ]; then
      sudo docker pull jlesage/firefox:latest

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

      docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/usr/bin/docker -v $PWD:/firefox docker:18.06.2-dind /bin/sh -c 'apk add --no-cache bash && cd /firefox && chmod +x /firefox/restart.sh && while true; do sleep 3600; /firefox/restart.sh --restartFirefox; done')
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
      eb_port="-p $local_IP_address:$ebesucher_first_port:5800"
    fi

    # Setting random window height and width for firefox
    if [ "$EBESUCHER_USE_RANDOM_DISPLAY" = true ]; then
      MIN_WIDTH=1280
      MIN_HEIGHT=1024
      WINDOW_WIDTH=$((RANDOM % (1920 - MIN_WIDTH + 1) + MIN_WIDTH))
      WINDOW_HEIGHT=$((RANDOM % (1080 - MIN_HEIGHT + 1) + MIN_HEIGHT))
      DISPLAY_PARAMETERS="-e DISPLAY_WIDTH=$WINDOW_WIDTH  -e DISPLAY_HEIGHT=$WINDOW_HEIGHT"
    fi

    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -e KEEP_APP_RUNNING=1 -e FF_OPEN_URL="https://www.ebesucher.com/surfbar/$EBESUCHER_USERNAME" $DISPLAY_PARAMETERS -e VNC_LISTENING_PORT=-1 -e VNC_PASSWORD="internetincome" -v $PWD/$firefox_data_folder/data$i:/config:rw $eb_port jlesage/firefox:latest)
    execute_docker_command "Ebesucher" "ebesucher$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the following node url and paste in your browser if required..${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $ebesucher_file in the same folder${NOCOLOUR}"
    echo "http://$localhost_address:$ebesucher_first_port" |tee -a $ebesucher_file
    echo "ebesucher$UNIQUE_ID$i" | tee -a $firefox_containers_file
    ebesucher_first_port=`expr $ebesucher_first_port + 1`
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Ebesucher username for firefox is not configured. Ignoring Ebesucher..${NOCOLOUR}"
    fi
  fi

# Starting Ebesucher Chrome container
  if [[ $EBESUCHER_USERNAME && "$EBESUCHER_USE_CHROME" = true ]]; then
    if [ "$docker_in_docker_detected" = true ]; then
      echo -e "${RED}Adnade and Ebesucher are not supported now in Docker-in-Docker. Kindly use custom chrome or custom firefox and login manually. Exiting..${NOCOLOUR}";
      exit 1
    fi
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

      docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/usr/bin/docker -v $PWD:/chrome docker:18.06.2-dind /bin/sh -c 'apk add --no-cache bash && cd /chrome && chmod +x /chrome/restart.sh && while true; do sleep 3600; /chrome/restart.sh --restartChrome; done')
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
      eb_port="-p $local_IP_address:$ebesucher_first_port:3000 "
    fi

    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN --security-opt seccomp=unconfined -e TZ=Etc/UTC -e CHROME_CLI="https://www.ebesucher.com/surfbar/$EBESUCHER_USERNAME" -e CUSTOM_USER="internetincome" -e PASSWORD="internetincome" -v $PWD/$chrome_data_folder/data$i/$chrome_profile_data:/config --shm-size="1gb" $eb_port lscr.io/linuxserver/chromium:latest)
    execute_docker_command "Ebesucher" "ebesucher$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the following node url and paste in your browser if required..${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $ebesucher_file in the same folder${NOCOLOUR}"
    echo "http://$localhost_address:$ebesucher_first_port" |tee -a $ebesucher_file
    echo "ebesucher$UNIQUE_ID$i" | tee -a $chrome_containers_file
    ebesucher_first_port=`expr $ebesucher_first_port + 1`
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Ebesucher username for chrome is not configured. Ignoring Ebesucher..${NOCOLOUR}"
    fi
  fi

  # Starting Adnade Firefox container
  if [[ $ADNADE_USERNAME && "$ADNADE_USE_CHROME" != true  ]]; then
    if [ "$docker_in_docker_detected" = true ]; then
      echo -e "${RED}Adnade and Ebesucher are not supported now in Docker-in-Docker. Kindly use custom chrome or custom firefox and login manually. Exiting..${NOCOLOUR}";
      exit 1
    fi
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

      docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/usr/bin/docker -v $PWD:/firefox docker:18.06.2-dind /bin/sh -c 'apk add --no-cache bash && cd /firefox && chmod +x /firefox/restart.sh && while true; do sleep 7200; /firefox/restart.sh --restartAdnadeFirefox; done')
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
      ad_port="-p $local_IP_address:$adnade_first_port:5900"
    fi

    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -e FF_CUSTOM_ARGS="--private-window" -e FF_OPEN_URL="https://adnade.net/view.php?user=$ADNADE_USERNAME&multi=4" -e VNC_LISTENING_PORT=-1 -e WEB_LISTENING_PORT=5900 -e VNC_PASSWORD="internetincome" -v $PWD/$adnade_data_folder/data$i:/config:rw $ad_port jlesage/firefox:latest)
    execute_docker_command "Adnade" "adnade$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the following node url and paste in your browser if required..${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $adnade_file in the same folder${NOCOLOUR}"
    echo "http://$localhost_address:$adnade_first_port" |tee -a $adnade_file
    echo "adnade$UNIQUE_ID$i" | tee -a $adnade_containers_file
    adnade_first_port=`expr $adnade_first_port + 1`
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Adnade username for firefox is not configured. Ignoring Adnade..${NOCOLOUR}"
    fi
  fi

  # Starting Adnade Chrome container
  if [[ $ADNADE_USERNAME && "$ADNADE_USE_CHROME" = true ]]; then
    if [ "$docker_in_docker_detected" = true ]; then
      echo -e "${RED}Adnade and Ebesucher are not supported now in Docker-in-Docker. Kindly use custom chrome or custom firefox and login manually. Exiting..${NOCOLOUR}";
      exit 1
    fi
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

      docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/usr/bin/docker -v $PWD:/chrome docker:18.06.2-dind /bin/sh -c 'apk add --no-cache bash && cd /chrome && chmod +x /chrome/restart.sh && while true; do sleep 7200; /chrome/restart.sh --restartAdnade; done')
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
      ad_port="-p $local_IP_address:$adnade_first_port:3500 "
    fi

    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN --security-opt seccomp=unconfined -e TZ=Etc/UTC -e CUSTOM_HTTPS_PORT=3501 -e CUSTOM_PORT=3500 -e CHROME_CLI="--incognito https://adnade.net/view.php?user=$ADNADE_USERNAME&multi=4" -e CUSTOM_USER="internetincome" -e PASSWORD="internetincome" -v $PWD/$adnade_data_folder/data$i/$chrome_profile_data:/config --shm-size="1gb" $ad_port lscr.io/linuxserver/chromium:latest)
    execute_docker_command "Adnade" "adnade$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the following node url and paste in your browser if required..${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $adnade_file in the same folder${NOCOLOUR}"
    echo "http://$localhost_address:$adnade_first_port" |tee -a $adnade_file
    echo "adnade$UNIQUE_ID$i" | tee -a $adnade_containers_file
    adnade_first_port=`expr $adnade_first_port + 1`
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
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
    if [ ! -f "$PWD/$bitping_data_folder/data$i/.bitpingd/node.db" ]; then
        sudo docker run --rm $NETWORK_TUN -v "$PWD/$bitping_data_folder/data$i/.bitpingd:/root/.bitpingd" --entrypoint /app/bitpingd bitping/bitpingd:latest login --email $BITPING_EMAIL --password $BITPING_PASSWORD
    fi
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -v "$PWD/$bitping_data_folder/data$i/.bitpingd:/root/.bitpingd" bitping/bitpingd:latest)
    execute_docker_command "BitPing" "bitping$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}BitPing Node is not enabled. Ignoring BitPing..${NOCOLOUR}"
    fi
  fi

  # Starting Repocket container
  if [[ $REPOCKET_EMAIL && $REPOCKET_API ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull repocket/repocket:latest
    fi
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -e RP_EMAIL=$REPOCKET_EMAIL -e RP_API_KEY=$REPOCKET_API repocket/repocket:latest)
    execute_docker_command "Repocket" "repocket$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Repocket Email or Api is not configured. Ignoring Repocket..${NOCOLOUR}"
    fi
  fi

  # Starting Traffmonetizer container
  if [[ $TRAFFMONETIZER_TOKEN ]]; then
    if [ "$CPU_ARCH" == "aarch64" ] || [ "$CPU_ARCH" == "arm64" ]; then
      traffmonetizer_image="traffmonetizer/cli_v2:arm64v8"
    elif [ "$CPU_ARCH" == "armv7l" ]; then
      traffmonetizer_image="traffmonetizer/cli_v2:arm32v7"
    else
      traffmonetizer_image="--platform=linux/amd64 traffmonetizer/cli_v2:latest"
    fi
    if [ "$container_pulled" = false ]; then
      sudo docker pull $traffmonetizer_image
    fi
    mkdir -p $PWD/$traffmonetizer_data_folder/data$i
    sudo chmod -R 777 $PWD/$traffmonetizer_data_folder/data$i
    traffmonetizer_volume="-v $PWD/$traffmonetizer_data_folder/data$i:/app/traffmonetizer"
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN $traffmonetizer_volume $traffmonetizer_image start accept --device-name $DEVICE_NAME$i --token $TRAFFMONETIZER_TOKEN)
    execute_docker_command "Traffmonetizer" "traffmon$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Traffmonetizer Token is not configured. Ignoring Traffmonetizer..${NOCOLOUR}"
    fi
  fi

  # Starting URnetwork container
  if [[ $UR_AUTH_TOKEN ]]; then
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
      if [ "$UR_NETWORK_PROXY_MODE" = true ]; then
        if [ -f "$proxies_file" ]; then
          SOCKS_PROXIES=()
          while IFS= read -r line; do
            # Skip empty lines
            [[ -z "$line" ]] && continue
            if [[ "$line" == socks5://* ]]; then
              # Remove socks5:// prefix for config format
              SOCKS_PROXY=$line
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
	          if [[ $SOCKS_USER && $SOCKS_PASS ]]; then
                echo "$SOCKS_ADDR:$SOCKS_PORT:$SOCKS_USER:$SOCKS_PASS" >> $ur_proxies_file
              else
                echo "$SOCKS_ADDR:$SOCKS_PORT" >> $ur_proxies_file
              fi
            fi
          done < "$proxies_file"
        fi
	    if [ ! -f "$ur_proxies_file" ]; then
          echo -e "${RED}Proxies file $ur_proxies_file does not have socks5 proxies. Exiting..${NOCOLOUR}"
          exit 1
        fi
	    # Generate proxy file using urnetwork
	    sudo docker run --rm $DNS_VOLUME -v "$PWD/$urnetwork_data_folder/data/.urnetwork:/root/.urnetwork" -v "$PWD/$ur_proxies_file:/root/ur_proxy.txt" bringyour/community-provider:latest proxy add --proxy_file=/root/ur_proxy.txt
	    sleep 1
	    if [ ! -f "$PWD/$urnetwork_data_folder/data/.urnetwork/proxy" ]; then
          echo -e "${RED}Proxy file could not be generated for URnetwork. Exiting..${NOCOLOUR}"
          exit 1
        fi
	    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM -v "$PWD/$urnetwork_data_folder/data/.urnetwork:/root/.urnetwork" bringyour/community-provider:latest provide)
        execute_docker_command "URnetwork" "urnetwork$UNIQUE_ID$i" "${docker_parameters[@]}"
      else 
        docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/usr/bin/docker -v $PWD:/urnetwork docker:18.06.2-dind /bin/sh -c 'apk add --no-cache bash && cd /urnetwork && chmod +x /urnetwork/restart.sh && while true; do sleep 86400; /urnetwork/restart.sh --restartURnetwork; done')
        execute_docker_command "URnetwork Restart" "dindurnetwork$UNIQUE_ID$i" "${docker_parameters[@]}"
      fi
    fi 
    if [ "$UR_NETWORK_PROXY_MODE" != true ]; then
      docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -v "$PWD/$urnetwork_data_folder/data/.urnetwork:/root/.urnetwork" bringyour/community-provider:latest provide)
      execute_docker_command "URnetwork" "urnetwork$UNIQUE_ID$i" "${docker_parameters[@]}"
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}URnetwork Node is not enabled. Ignoring URnetwork..${NOCOLOUR}"
    fi
  fi

  # Starting PacketShare container
  if [[ $PACKETSHARE_EMAIL && $PACKETSHARE_PASSWORD ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull packetshare/packetshare:latest
    fi
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN packetshare/packetshare:latest -accept-tos -email=$PACKETSHARE_EMAIL -password=$PACKETSHARE_PASSWORD)
    execute_docker_command "PacketShare" "packetshare$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}PacketShare Email or Password is not configured. Ignoring PacketShare..${NOCOLOUR}"
    fi
  fi

  # Starting Depin Chrome Extensions container
  if [[ $GRASS_EMAIL && $GRASS_PASSWORD ]] || [[ $GRADIENT_EMAIL && $GRADIENT_PASSWORD ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull carbon2029/dockweb:latest
    fi
    if [[ $GRASS_EMAIL && $GRASS_PASSWORD ]]; then
      grass_env="-e GRASS_USER=$GRASS_EMAIL -e GRASS_PASS=$GRASS_PASSWORD"
    fi
    if [[ $GRADIENT_EMAIL && $GRADIENT_PASSWORD ]]; then
      gradient_env="-e GRADIENT_EMAIL=$GRADIENT_EMAIL -e GRADIENT_PASS=$GRADIENT_PASSWORD"
    fi
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN $grass_env $gradient_env carbon2029/dockweb:latest)
    execute_docker_command "Depin Extensions" "depinext$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Depin Extensions are not configured. Ignoring Depin Extensions..${NOCOLOUR}"
    fi
  fi

  # Starting Earn FM container
  if [[ $EARN_FM_API && "$USE_EARN_FM_FLEETSHARE" != true ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull earnfm/earnfm-client:latest
    fi
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -e EARNFM_TOKEN=$EARN_FM_API earnfm/earnfm-client:latest)
    execute_docker_command "EarnFM" "earnfm$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}EarnFM Api is not configured. Ignoring EarnFM..${NOCOLOUR}"
    fi
  fi

   # Starting Earn FM Fleetshare container
  if [[ $EARN_FM_API && "$USE_EARN_FM_FLEETSHARE" = true ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull earnfm/fleetshare:latest
      if [ -f "$proxies_file" ]; then
        SOCKS_PROXIES=()
        while IFS= read -r line; do
          # Skip empty lines
          [[ -z "$line" ]] && continue
          if [[ "$line" == socks5://* ]]; then
            # Remove socks5:// prefix for config format
            earn_proxy="${line#socks5://}"
            SOCKS_PROXIES+=("\"$earn_proxy\"")
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
        docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM -v $PWD/$earn_fm_config_file:/app/config.json earnfm/fleetshare:latest)
        execute_docker_command "EarnFM Fleetshare" "earnfm$UNIQUE_ID$i" "${docker_parameters[@]}"
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
    if [ "$container_pulled" = false ]; then
      sudo docker pull packetsdk/packetsdk:latest
    fi
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN packetsdk/packetsdk:latest -appkey=$PACKET_SDK_APP_KEY)
    execute_docker_command "PacketSDK" "packetsdk$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}PacketSDK API is not configured. Ignoring PacketSDK..${NOCOLOUR}"
    fi
  fi

  # Starting ProxyRack container
  if [[ $PROXYRACK_API ]]; then
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
      sudo docker pull --platform=linux/amd64 proxyrack/pop:latest
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
        proxyrack_uuid=$RANDOM_ID
        printf "%s\n" "$proxyrack_uuid" | tee -a $proxyrack_file
      fi
    else
      echo "Proxyrack UUID does not exist, creating UUID"
      proxyrack_uuid=$RANDOM_ID
      printf "%s\n" "$proxyrack_uuid" | tee -a $proxyrack_file
    fi
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM --platform=linux/amd64 $NETWORK_TUN -e UUID=$proxyrack_uuid -e DEVICE_NAME=$DEVICE_NAME$i -e API_KEY=$PROXYRACK_API proxyrack/pop:latest)
    execute_docker_command "ProxyRack" "proxyrack$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Device is automatically addded to your proxyrack dashboard after 5 minutes${NOCOLOUR}"
    echo -e "${GREEN}You will find the uuids in the file $proxyrack_file in the same folder${NOCOLOUR}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}ProxyRack Api is not configured. Ignoring ProxyRack..${NOCOLOUR}"
    fi
  fi

  # Starting ProxyBase container
  if [[ "$PROXYBASE_ACCOUNT_ID" ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull proxybase/proxybase:latest
    fi
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -e DEVICE_NAME=$DEVICE_NAME$i -e USER_ID=$PROXYBASE_ACCOUNT_ID proxybase/proxybase:latest)
    execute_docker_command "ProxyBase" "proxybase$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}ProxyBase is not enabled. Ignoring ProxyBase..${NOCOLOUR}"
    fi
  fi

  # Starting IPRoyals pawns container
  if [[ $IPROYALS_EMAIL && $IPROYALS_PASSWORD ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull iproyal/pawns-cli:latest
    fi
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN iproyal/pawns-cli:latest -email=$IPROYALS_EMAIL -password=$IPROYALS_PASSWORD -device-name=$DEVICE_NAME$i -device-id=$DEVICE_NAME$i -accept-tos)
    execute_docker_command "IPRoyals" "pawns$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}IPRoyals Email or Password is not configured. Ignoring IPRoyals..${NOCOLOUR}"
    fi
  fi

  # Starting Wipter container
  if [[ $WIPTER_EMAIL && $WIPTER_PASSWORD ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull techroy23/docker-wipter:latest
    fi
    if [[ "$NETWORK_TUN" == --network=multi* || -z "$proxy" ]]; then
      WIPTER_HOST_NAME="--hostname $DEVICE_NAME$i"
    fi
    docker_parameters=($WIPTER_HOST_NAME $LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -e WIPTER_EMAIL=$WIPTER_EMAIL -e WIPTER_PASSWORD=$WIPTER_PASSWORD techroy23/docker-wipter:latest)
    execute_docker_command "Wipter" "wipter$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Wipter Email or Password is not configured. Ignoring Wipter..${NOCOLOUR}"
    fi
  fi

  # Starting Honeygain container
  if [[ $HONEYGAIN_EMAIL && $HONEYGAIN_PASSWORD ]]; then
    if [[ $NETWORK_TUN ]]; then
      if [ "$CPU_ARCH" == "x86_64" ] || [ "$CPU_ARCH" == "amd64" ]; then
        honeygain_image="honeygain/honeygain:0.6.6"
      else
        honeygain_image="honeygain/honeygain:latest"
      fi
    else
      honeygain_image="honeygain/honeygain:latest"
    fi
    if [ "$container_pulled" = false ]; then
      sudo docker pull $honeygain_image
    fi
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN $honeygain_image -tou-accept -email $HONEYGAIN_EMAIL -pass $HONEYGAIN_PASSWORD -device $DEVICE_NAME$i)
    execute_docker_command "Honeygain" "honey$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Honeygain Email or Password is not configured. Ignoring Honeygain..${NOCOLOUR}"
    fi
  fi

  # Starting Honeygain Pot container
  if [[ $HONEYGAIN_EMAIL && $HONEYGAIN_PASSWORD && "$HONEYGAIN_POT" = true ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull xterna/honeygain-pot:latest
      docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -e EMAIL=$HONEYGAIN_EMAIL -e PASSWORD=$HONEYGAIN_PASSWORD xterna/honeygain-pot:latest)
      execute_docker_command "HoneygainPot" "honeygainpot$UNIQUE_ID$i" "${docker_parameters[@]}"
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Honeygain Pot is not enabled. Ignoring Honeygain Pot..${NOCOLOUR}"
    fi
  fi

  # Starting Gaganode container
  if [[ $GAGANODE_TOKEN ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull xterna/gaga-node:latest
    fi
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -e TOKEN=$GAGANODE_TOKEN xterna/gaga-node:latest)
    execute_docker_command "Gaganode" "gaganode$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Gaganode Token is not configured. Ignoring Gaganode..${NOCOLOUR}"
    fi
  fi

  # Starting Titan Network container
  if [[ $TITAN_HASH ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull nezha123/titan-edge:latest
      mkdir -p $PWD/$titan_data_folder/data$i
      sudo chmod -R 777 $PWD/$titan_data_folder/data$i
      titan_volume="-v $PWD/$titan_data_folder/data$i:/root/.titanedge"
      docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN $titan_volume nezha123/titan-edge:latest)
      execute_docker_command "TitanNetwork" "titan$UNIQUE_ID$i" "${docker_parameters[@]}"
      sleep 5
      sudo docker run --rm -it $titan_volume nezha123/titan-edge bind --hash=$TITAN_HASH https://api-test1.container1.titannet.io/api/v2/device/binding
      echo -e "${GREEN}The current script is designed to support only a single device for the Titan Network. Please create a new folder, download the InternetIncome script, and add the appropriate hash for the new device.${NOCOLOUR}"
    fi
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Titan Network Hash is not configured. Ignoring Titan Network..${NOCOLOUR}"
    fi
  fi

  # Starting AntGain container
  if [[ $ANTGAIN_API_KEY ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull --platform=linux/amd64 pinors/antgain-cli:latest
    fi
    docker_parameters=(--platform=linux/amd64 $LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -e ANTGAIN_API_KEY=$ANTGAIN_API_KEY --no-healthcheck pinors/antgain-cli:latest run)
    execute_docker_command "AntGain" "antgain$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}AntGain API is not configured. Ignoring AntGain..${NOCOLOUR}"
    fi
  fi

  # Starting Peer2Profit container
  if [[ $PEER2PROFIT_EMAIL ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull --platform=linux/amd64 enwaiax/peer2profit:latest
    fi
    docker_parameters=(--platform=linux/amd64 $LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -e email=$PEER2PROFIT_EMAIL enwaiax/peer2profit:latest)
    execute_docker_command "Peer2Profit" "peer2profit$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Peer2Profit Email is not configured. Ignoring Peer2Profit..${NOCOLOUR}"
    fi
  fi

  # Starting WizardGain container
  if [[ $WIZARD_GAIN_EMAIL ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull wizardgain/worker:latest
    fi
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -e EMAIL=$WIZARD_GAIN_EMAIL wizardgain/worker:latest)
    execute_docker_command "WizardGain" "wizardgain$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}WizardGain Email is not configured. Ignoring WizardGain..${NOCOLOUR}"
    fi
  fi

  # Starting Nodepay container
  if [[ $NP_COOKIE ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull kellphy/nodepay:latest
    fi
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -e NP_COOKIE=$NP_COOKIE kellphy/nodepay:latest)
    execute_docker_command "Nodepay" "nodepay$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Nodepay cookie is not configured. Ignoring Nodepay..${NOCOLOUR}"
    fi
  fi

  # Starting CastarSDK container
  if [[ $CASTAR_SDK_KEY ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull ghcr.io/bhavishyadahiya/castarsdk-docker/castarsdk@sha256:249a098b4da0a52be412cd05f312447d7ec348d8cb8cfb6a3ed61b44f9f4af40
    fi
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -e KEY=$CASTAR_SDK_KEY ghcr.io/bhavishyadahiya/castarsdk-docker/castarsdk@sha256:249a098b4da0a52be412cd05f312447d7ec348d8cb8cfb6a3ed61b44f9f4af40)
    execute_docker_command "CastarSDK" "castarsdk$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}CastarSDK is not configured. Ignoring CastarSDK..${NOCOLOUR}"
    fi
  fi

  # Starting PacketStream container
  if [[ $PACKETSTREAM_CID ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull packetstream/psclient:latest
    fi
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -e CID=$PACKETSTREAM_CID packetstream/psclient:latest)
    execute_docker_command "PacketStream" "packetstream$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}PacketStream CID is not configured. Ignoring PacketStream..${NOCOLOUR}"
    fi
  fi

  # Starting Proxylite container
  if [[ $PROXYLITE_USER_ID ]]; then
    if [ "$container_pulled" = false ]; then
      sudo docker pull proxylite/proxyservice:latest
    fi
    docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM --platform=linux/amd64 $NETWORK_TUN -e USER_ID=$PROXYLITE_USER_ID proxylite/proxyservice:latest)
    execute_docker_command "Proxylite" "proxylite$UNIQUE_ID$i" "${docker_parameters[@]}"
  else
    if [[ "$container_pulled" == false && "$ENABLE_LOGS" == true ]]; then
      echo -e "${RED}Proxylite is not configured. Ignoring Proxylite..${NOCOLOUR}"
    fi
  fi

  # Starting Earnapp container
  if [ "$EARNAPP" = true ]; then
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
      sudo docker pull madereddy/earnapp:latest
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
    local EARNAPP_PRIVILEGED
    if [[ "$USE_EARNAPP_PRIVILEGED" = true ]]; then
      EARNAPP_PRIVILEGED="--privileged"
    fi
    docker_parameters=($EARNAPP_PRIVILEGED $LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -v $PWD/$earnapp_data_folder/data$i:/etc/earnapp -e EARNAPP_UUID=$uuid --no-healthcheck madereddy/earnapp:latest)
    execute_docker_command "Earnapp" "earnapp$UNIQUE_ID$i" "${docker_parameters[@]}"
    echo -e "${GREEN}Copy the node url and paste in your earnapp dashboard${NOCOLOUR}"
    echo -e "${GREEN}You will also find the urls in the file $earnapp_file in the same folder${NOCOLOUR}"
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
  echo -e "To install Docker, please run the following command\n"
  echo -e "${YELLOW}sudo bash internetIncome.sh --install${NOCOLOUR}\n"
  exit 1
fi

if [[ "$1" == "--startOnly" ]]; then
  shift   # remove --startOnly
  # Read -e arguments and export variables to the current shell
  while [[ $# -gt 0 ]]; do
    # Look only for -e
    if [[ "$1" == "-e" ]]; then
      shift
      line="$1"
      # Split the line at the first occurrence of =
      key="${line%%=*}"
      value="${line#*=}"
      # Trim leading and trailing whitespace from key and value
      key="${key%"${key##*[![:space:]]}"}"
      value="${value%"${value##*[![:space:]]}"}"
      # Ignore lines without a value after =
      if [[ -n $value ]]; then
          # Replace variables with their values 
          value="$value"
          # Export the key-value pairs as variables
          export "$key"="$value"
      fi
    fi
    shift
  done
  # Check if connection state file exists
  if [ ! -f "$connection_state_file" ]; then
    echo -e "${RED}Required file $connection_state_file does not exist. Exiting..${NOCOLOUR}"
    exit 1
  fi
  # Check if container names file exists
  if [ ! -f "$container_names_file" ]; then
    echo -e "${RED}Required file $container_names_file does not exist. Exiting..${NOCOLOUR}"
    exit 1
  fi
  # Read the first line of the file
  CURRENT_ID=$(head -n 1 "$connection_state_file")
  if [ -n "$CURRENT_ID" ]; then
    UNIQUE_ID=$CURRENT_ID
  else
    echo -e "${RED}Unique ID is not present in $connection_state_file. Exiting..${NOCOLOUR}"
    exit 1
  fi
  START_ONLY=true
  if grep -q "DIRECT_CONNECTION_ENABLED" "$connection_state_file"; then
    start_containers
  fi
  i=0
  for container in `cat $container_names_file | grep ^gluetun`
  do
    i=`expr $i + 1`
    start_containers "$i" "$container" "true"
  done
  MULTI_IP_CONTAINER_COUNT=0
  if [ -f $networks_file ]; then
    # Count containers whose names start with 'multi'
    MULTI_IP_CONTAINER_COUNT=$(grep -c '^multi' "$networks_file")
  fi
  if [ "$MULTI_IP_CONTAINER_COUNT" -gt 0 ]; then
    # Check if container names file exists
    if [ ! -f "$multi_ip_file" ]; then
      echo -e "${RED}Required file $multi_ip_file does not exist. Exiting..${NOCOLOUR}"
      exit 1
    fi
    MULTI_IP_COUNT=0
    while IFS= read -r line || [ -n "$line" ]; do
      # Ignore lines starting with #
      if [[ "$line" =~ ^[^#].* ]]; then
        MULTI_IP_COUNT=$((MULTI_IP_COUNT + 1))
      fi
    done < $multi_ip_file
    # Check if both IP count and container count matches
    if [ "$MULTI_IP_CONTAINER_COUNT" -ne "$MULTI_IP_COUNT" ]; then
      echo -e "${RED}Multi IP Count does not match with the number of running containers. Exiting..${NOCOLOUR}"
      exit 1
    fi
    while IFS= read -r line || [ -n "$line" ]; do
      if [[ "$line" =~ ^[^#].* ]]; then
        i=`expr $i + 1`
        start_containers "$i" "$line" "false"
      fi
    done < $multi_ip_file
  fi
  for container in `cat $container_names_file | grep ^tun`
  do
    i=`expr $i + 1`
    start_containers "$i" "$container"
  done
  exit 1
fi

# Start the containers
if [[ "$1" == "--start" ]]; then
  echo -e "\n\nStarting.."
  STATUS=0;

  # Check if the required files are present
  for required_file in "${required_files[@]}"; do
    if [ ! -f "$required_file" ]; then
      echo -e "${RED}Required file $required_file does not exist. Exiting..${NOCOLOUR}"
      exit 1
    fi
  done

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

  # Remove special character ^M and trim space from properties file
  sed -i 's/\r//g' $properties_file
  sed -i 's/^[ \t]*//;s/[ \t]*$//' $properties_file

  # CPU architecture to get docker images
  CPU_ARCH=`uname -m`

  # Write current PID to file
  echo "$$" > $process_id_file

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

  # Write Unique ID to file
  echo $UNIQUE_ID > $connection_state_file

  # Use direct Connection
  if [ "$USE_DIRECT_CONNECTION" = true ]; then
     echo "DIRECT_CONNECTION_ENABLED" >> $connection_state_file
     STATUS=1
     echo -e "${GREEN}USE_DIRECT_CONNECTION is enabled, using direct internet connection..${NOCOLOUR}"
     start_containers
  fi

  # Use Vpns
  if [ "$USE_VPNS" = true ]; then
    echo "VPN_ENABLED" >> $connection_state_file
    STATUS=1
    echo -e "${GREEN}USE_VPNS is enabled, using vpns..${NOCOLOUR}"
    if [ ! -f "$vpns_file" ]; then
      echo -e "${RED}Vpns file $vpns_file does not exist. Exiting..${NOCOLOUR}"
      exit 1
    fi

    # Remove special character ^M and trim space from vpn file
    sed -i 's/\r//g' $vpns_file
    sed -i 's/^[ \t]*//;s/[ \t]*$//' $vpns_file
    if [ -z "${i}" ]; then
      i=0;
    fi
    while IFS= read -r line || [ -n "$line" ]; do
      if [[ "$line" =~ ^[^#].* ]]; then
        i=`expr $i + 1`
        start_containers "$i" "$line" "true"
      fi
    done < $vpns_file
  fi

  # Use Multi IPs
  if [ "$USE_MULTI_IP" = true ]; then
    echo "MULTI_IP_ENABLED" >> $connection_state_file
    STATUS=1
    echo -e "${GREEN}USE_MULTI_IP is enabled, using multi ip..${NOCOLOUR}"
    if [ ! -f "$multi_ip_file" ]; then
      echo -e "${RED}Multi IP file $multi_ip_file does not exist. Exiting..${NOCOLOUR}"
      exit 1
    fi

    # Remove special character ^M and trim space from multi ip file
    sed -i 's/\r//g' $multi_ip_file
    sed -i 's/^[ \t]*//;s/[ \t]*$//' $multi_ip_file
    if [ -z "${i}" ]; then
      i=0;
    fi
    while IFS= read -r line || [ -n "$line" ]; do
      if [[ "$line" =~ ^[^#].* ]]; then
        i=`expr $i + 1`
        start_containers "$i" "$line" "false"
      fi
    done < $multi_ip_file
  fi

  # Use Proxies
  if [ "$USE_PROXIES" = true ]; then
    echo "PROXY_ENABLED" >> $connection_state_file
    STATUS=1
    echo -e "${GREEN}USE_PROXIES is enabled, using proxies..${NOCOLOUR}"
    if [ ! -f "$proxies_file" ]; then
      echo -e "${RED}Proxies file $proxies_file does not exist. Exiting..${NOCOLOUR}"
      exit 1
    fi

    # Remove special character ^M and trim space from proxies file
    sed -i 's/\r//g' $proxies_file
    sed -i 's/^[ \t]*//;s/[ \t]*$//' $proxies_file
    if [ -z "${i}" ]; then
      i=0;
    fi
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

  if [ "$AUTO_UPDATE_CONTAINERS" = true ]; then
    # Check if watch tower container exists
    if sudo docker inspect $WATCH_TOWER_NAME >/dev/null 2>&1; then
      echo "InternetIncome Watchtower is already present on the host. One Watchtower container is enough to update all the containers. Not creating another instance to avoid redundant updates and resource usage."
    else
      docker_parameters=($LOGS_PARAM $DNS_VOLUME $MAX_MEMORY_PARAM $MEMORY_RESERVATION_PARAM $MEMORY_SWAP_PARAM $CPU_PARAM $NETWORK_TUN -e WATCHTOWER_CLEANUP=true -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --label-enable --interval 86400)
      execute_docker_command "Internet Income Watch Tower" "$WATCH_TOWER_NAME" "${docker_parameters[@]}"
    fi
  fi

  # Remove Process file
  rm $process_id_file
  exit 1
fi

# Delete containers and networks
if [[ "$1" == "--delete" ]]; then
  echo -e "\n\nDeleting Containers and networks.."
  # Check if there is already a running process
  if [ -f "$process_id_file" ]; then
    PID=$(cat "$process_id_file")
    PROC_DIR=$(pwdx "$PID" 2>/dev/null | awk '{print $2}')
    if [ "$PROC_DIR" = "$PWD" ]; then
      echo "There is already a running process (PID $PID)."
      echo "Do you want to stop it and continue? (yes/no)"
      # Prompt with 60-second timeout
      read -r -t 60 ANSWER
      if [ $? -ne 0 ]; then
        echo "No response within 60 seconds. Exiting."
        exit 1
      fi
      case "$ANSWER" in
        yes|y|Y)
          echo "Stopping process $PID..."
          kill "$PID" 2>/dev/null
          sleep 2
          rm -f "$process_id_file"
          echo "Process stopped. Continuing..."
          ;;
        no|n|N)
          echo "Operation cancelled."
          exit 1
          ;;
        *)
          echo "Invalid response. Exiting."
          exit 1
          ;;
      esac
    fi
  fi

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
  if [ -f "$subnets_file" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      if [[ "$line" =~ ^[^#].* ]]; then
        subnet=`echo $line | awk '{print $1}'`
        ip=`echo $line | awk '{print $2}'`
        sudo iptables -t nat -D POSTROUTING -s $subnet -j SNAT --to-source $ip
      fi
    done < $subnets_file
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
  folders_to_be_removed+=("${files_to_be_removed[@]}")
  for folder in "${folders_to_be_removed[@]}"; do
    if [ -d "$folder" ]; then
      rm -Rf $folder;
    fi
  done

  # Delete folders for Docker-in-Docker
  sudo docker run --rm -v "$PWD:/output" docker:18.06.2-dind sh -c 'for folder in "$@"; do if [ -d "/output/$folder" ]; then rm -rf "/output/$folder"; fi; done' sh "${folders_to_be_removed[@]}"

  exit 1
fi

# Stop containers
if [[ "$1" == "--stop" ]]; then
  echo -e "\n\nStopping Containers.."

  # Stop containers by container names
  if [ -f "$container_names_file" ]; then
    for i in `cat $container_names_file`; do
      # Check if container exists
      if sudo docker inspect $i >/dev/null 2>&1; then
        # Stop container
        sudo docker stop $i
      else
        echo "Container $i does not exist"
      fi
    done
  fi
  exit 1
fi

# Restart containers
if [[ "$1" == "--restart" ]]; then
  echo -e "\n\nRestarting Containers.."

  # Restart containers by container names
  if [ -f "$container_names_file" ]; then
    for i in `cat $container_names_file`; do
      # Check if container exists
      if sudo docker inspect $i >/dev/null 2>&1; then
        # Restart container
        sudo docker restart $i
      else
        echo "Container $i does not exist"
      fi
    done
  fi
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
  back_up_folders+=("${back_up_files[@]}")
  for folder in "${back_up_folders[@]}"; do
    if [ -d "$folder" ]; then
      rm -Rf $folder;
    fi
  done

  # Delete backup folders for Docker-in-Docker
  sudo docker run --rm -v "$PWD:/output" docker:18.06.2-dind sh -c 'for folder in "$@"; do if [ -d "/output/$folder" ]; then rm -rf "/output/$folder"; fi; done' sh "${back_up_folders[@]}"

  exit 1
fi

echo -e "Valid options are: ${RED}--start${NOCOLOUR}, ${RED}--startOnly${NOCOLOUR}, ${RED}--delete${NOCOLOUR}, ${RED}--deleteBackup${NOCOLOUR}, ${RED}--stop${NOCOLOUR}, ${RED}--restart${NOCOLOUR}"
