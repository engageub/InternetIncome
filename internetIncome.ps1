#!/usr/bin/env pwsh

##################################################################################
# Author: tboy1337                                                               #
# Description: PowerShell version of InternetIncome for Windows                  #
# This script lets you earn passive income by sharing your internet connection.  #
# It also supports multiple proxies with multiple accounts.                      #
# Script Name: Internet Income (Supports Proxies) - Windows Version              #
# Script Link: https://github.com/engageub/InternetIncome                        #
# DISCLAIMER: This script is provided "as is" and without warranty of any kind.  #
# The author makes no warranties, express or implied, that this script is free of#
# errors, defects, or suitable for any particular purpose. The author shall not  #
# be liable for any damages suffered by any user of this script, whether direct, #
# indirect, incidental, consequential, or special, arising from the use of or    #
# inability to use this script or its documentation, even if the author has been #
# advised of the possibility of such damages.                                    #
##################################################################################

# Color definitions for Windows PowerShell
$RED = "Red"
$GREEN = "Green"
$YELLOW = "Yellow"
$NOCOLOUR = "White"

# File names (keeping the same as bash script)
$properties_file = "properties.conf"
$banner_file = "banner.jpg"
$proxies_file = "proxies.txt" # Will be used in the --start implementation
$containers_file = "containers.txt"
$container_names_file = "containernames.txt"
$earnapp_file = "earnapp.txt"
$earnapp_data_folder = "earnappdata"
$proxybase_file = "proxybase.txt"
$proxyrack_file = "proxyrack.txt"
$networks_file = "networks.txt"
$mysterium_file = "mysterium.txt"
$mysterium_data_folder = "mysterium-data"
$ebesucher_file = "ebesucher.txt"
$adnade_file = "adnade.txt"
$adnade_data_folder = "adnadedata"
$adnade_containers_file = "adnadecontainers.txt"
$firefox_containers_file = "firefoxcontainers.txt"
$chrome_containers_file = "chromecontainers.txt"
$bitping_data_folder = "bitping-data"
$firefox_data_folder = "firefoxdata"
$firefox_profile_data = "firefoxprofiledata"
$firefox_profile_zipfile = "firefoxprofiledata.zip"
$chrome_data_folder = "chromedata"
$chrome_profile_data = "chromeprofiledata"
$chrome_profile_zipfile = "chromeprofiledata.zip"
$restart_file = "restart.ps1"
$dns_resolver_file = "resolv.conf"
$traffmonetizer_data_folder = "traffmonetizerdata"
$network3_data_folder = "network3-data"
$titan_data_folder = "titan-data"
$required_files = @($banner_file, $properties_file, $firefox_profile_zipfile, $restart_file, $chrome_profile_zipfile)

# These variables will be used in the --delete and --deleteBackup implementations
$files_to_be_removed = @($dns_resolver_file, $containers_file, $container_names_file, $networks_file, $mysterium_file, $ebesucher_file, $adnade_file, $adnade_containers_file, $firefox_containers_file, $chrome_containers_file)
$folders_to_be_removed = @($adnade_data_folder, $firefox_data_folder, $firefox_profile_data, $earnapp_data_folder, $chrome_data_folder, $chrome_profile_data)
$back_up_folders = @($titan_data_folder, $network3_data_folder, $bitping_data_folder, $traffmonetizer_data_folder, $mysterium_data_folder)
$back_up_files = @($earnapp_file, $proxybase_file, $proxyrack_file)

$container_pulled = $false
$script:docker_in_docker_detected = $false # Using script: scope to avoid redefinition warning

# Mysterium and ebesucher first port
$mysterium_first_port = 2000
$ebesucher_first_port = 3000
$adnade_first_port = 4000

# Unique Id
$UNIQUE_ID = -join ((48..57) + (97..102) | Get-Random -Count 32 | ForEach-Object { [char]$_ })

# Display ASCII art banner with color cycling if banner file exists
function Show-Banner {
    if (Test-Path $banner_file) {
        for ($i = 0; $i -lt 3; $i++) {
            foreach ($color in @($RED, $GREEN, $YELLOW)) {
                Clear-Host
                Write-Host (Get-Content -Raw $banner_file) -ForegroundColor $color
                Start-Sleep -Milliseconds 500
            }
        }
        Write-Host
    }
}

# Check for open ports
function Test-OpenPorts {
    param (
        [int]$first_port,
        [int]$num_ports
    )

    $port_range = $first_port..($first_port + $num_ports - 1)
    $open_ports = 0

    foreach ($port in $port_range) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $connection = $tcpClient.BeginConnect('localhost', $port, $null, $null)
            $wait = $connection.AsyncWaitHandle.WaitOne(100)
            if ($wait) {
                $open_ports++
            }
            $tcpClient.Close()
        }
        catch {
            # Port is closed
        }
    }

    while ($open_ports -gt 0) {
        $first_port = $first_port + $num_ports
        $port_range = $first_port..($first_port + $num_ports - 1)
        $open_ports = 0
        
        foreach ($port in $port_range) {
            try {
                $tcpClient = New-Object System.Net.Sockets.TcpClient
                $connection = $tcpClient.BeginConnect('localhost', $port, $null, $null)
                $wait = $connection.AsyncWaitHandle.WaitOne(100)
                if ($wait) {
                    $open_ports++
                }
                $tcpClient.Close()
            }
            catch {
                # Port is closed
            }
        }
    }

    return $first_port
}

# Start containers
function Start-Containers {
    param (
        $i,
        $proxy
    )

    $DNS_VOLUME = "-v ${PWD}/$dns_resolver_file`:/etc/resolv.conf:ro"
    $TUN_DNS_VOLUME = $null

    if (-not $container_pulled) {
        # Create DNS resolver file
        'nameserver 8.8.8.8', 'nameserver 8.8.4.4', 'nameserver 1.1.1.1', 'nameserver 1.0.0.1', 'nameserver 9.9.9.9' | 
            Out-File -FilePath $dns_resolver_file -Encoding ascii
        
        if (-not (Test-Path $dns_resolver_file)) {
            Write-Host "There is a problem creating resolver file. Exiting.." -ForegroundColor $RED
            exit 1
        }
        
        # Check for Docker-in-Docker
        docker run --rm -v "${PWD}:/output" docker:18.06.2-dind sh -c "if [ ! -f /output/$dns_resolver_file ]; then exit 0; else exit 1; fi" | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $script:docker_in_docker_detected = $true
        }
        
        docker run --rm -v ${PWD}:/output docker:18.06.2-dind sh -c "if [ ! -f /output/$dns_resolver_file ]; then printf 'nameserver 8.8.8.8\nnameserver 8.8.4.4\nnameserver 1.1.1.1\nnameserver 1.0.0.1\nnameserver 9.9.9.9\n' > /output/$dns_resolver_file; printf 'Docker-in-Docker is detected. The script runs with limited features.\nThe files and folders are created in the same path on the host where your parent docker is installed.\n'; fi"
    }

    # Configure log parameters
    if ($ENABLE_LOGS -ne $true) {
        $LOGS_PARAM = "--log-driver none"
        $TUN_LOG_PARAM = "silent"
    }
    else {
        $LOGS_PARAM = "--log-driver=json-file --log-opt max-size=100k"
        $TUN_LOG_PARAM = "debug"
    }

    # Start proxy container if specified
    if ($i -and $proxy) {
        $NETWORK_TUN = "--network=container:tun$UNIQUE_ID$i"

        # Configure Mysterium port if enabled
        if ($MYSTERIUM -eq $true) {
            $mysterium_first_port = Test-OpenPorts $mysterium_first_port 1
            if (-not ($mysterium_first_port -match '^\d+$')) {
                Write-Host "Problem assigning port $mysterium_first_port .." -ForegroundColor $RED
                Write-Host "Failed to start Mysterium node. Resolve or disable Mysterium to continue. Exiting.." -ForegroundColor $RED
                exit 1
            }
            $mysterium_port = "-p $mysterium_first_port`:4449 "
        }

        # Configure Ebesucher port if enabled
        if ($EBESUCHER_USERNAME) {
            $ebesucher_first_port = Test-OpenPorts $ebesucher_first_port 1
            if (-not ($ebesucher_first_port -match '^\d+$')) {
                Write-Host "Problem assigning port $ebesucher_first_port .." -ForegroundColor $RED
                Write-Host "Failed to start Ebesucher. Resolve or disable Ebesucher to continue. Exiting.." -ForegroundColor $RED
                exit 1
            }
            if ($EBESUCHER_USE_CHROME -eq $true) {
                $ebesucher_port = "-p $ebesucher_first_port`:3000 "
            }
            else {
                $ebesucher_port = "-p $ebesucher_first_port`:5800 "
            }
        }

        # Configure Adnade port if enabled
        if ($ADNADE_USERNAME) {
            $adnade_first_port = Test-OpenPorts $adnade_first_port 1
            if (-not ($adnade_first_port -match '^\d+$')) {
                Write-Host "Problem assigning port $adnade_first_port .." -ForegroundColor $RED
                Write-Host "Failed to start Adnade. Resolve or disable Adnade to continue. Exiting.." -ForegroundColor $RED
                exit 1
            }
            $adnade_port = "-p $adnade_first_port`:5900 "
        }

        $combined_ports = $mysterium_port + $ebesucher_port + $adnade_port
        Write-Host "Starting Proxy container.." -ForegroundColor $GREEN
        
        # Pull tun2socks image if needed
        if (-not $container_pulled) {
            docker pull xjasonlyu/tun2socks:v2.5.2
        }
        
        # Configure DNS settings
        if ($USE_SOCKS5_DNS -eq $true) {
            $TUN_DNS_VOLUME = $DNS_VOLUME
        }
        elseif ($USE_DNS_OVER_HTTPS -eq $true) {
            $EXTRA_COMMANDS = 'echo -e "options use-vc\nnameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf;ip rule add iif lo ipproto udp dport 53 lookup main;'
        }
        else {
            $TUN_DNS_VOLUME = $DNS_VOLUME
            $EXTRA_COMMANDS = 'ip rule add iif lo ipproto udp dport 53 lookup main;'
        }
        
        # Start tun container
        $containerCmd = "docker run --name tun$UNIQUE_ID$i $LOGS_PARAM $TUN_DNS_VOLUME --restart=always -e LOGLEVEL=$TUN_LOG_PARAM -e PROXY=$proxy -e EXTRA_COMMANDS=`"$EXTRA_COMMANDS`" -v '/dev/net/tun:/dev/net/tun' --cap-add=NET_ADMIN $combined_ports -d xjasonlyu/tun2socks:v2.5.2"
        $CONTAINER_ID = Invoke-Expression $containerCmd
        
        if ($LASTEXITCODE -eq 0) {
            $CONTAINER_ID | Out-File -FilePath $containers_file -Append
            "tun$UNIQUE_ID$i" | Out-File -FilePath $container_names_file -Append
        }
        else {
            Write-Host "Failed to start container for proxy. Exiting.." -ForegroundColor $RED
            exit 1
        }
        Start-Sleep -Seconds 1
    }

    # Start Mysterium container if enabled
    if (($MYSTERIUM -eq $true) -and (-not $NETWORK_TUN)) {
        Write-Host "Starting Mysterium container.." -ForegroundColor $GREEN
        Write-Host "Copy the following node url and paste in your browser" -ForegroundColor $GREEN
        Write-Host "You will also find the urls in the file $mysterium_file in the same folder" -ForegroundColor $GREEN
        
        if (-not $container_pulled) {
            docker pull mysteriumnetwork/myst:latest
        }
        
        if (-not $proxy) {
            $mysterium_first_port = Test-OpenPorts $mysterium_first_port 1
            if (-not ($mysterium_first_port -match '^\d+$')) {
                Write-Host "Problem assigning port $mysterium_first_port .." -ForegroundColor $RED
                Write-Host "Failed to start Mysterium node. Resolve or disable Mysterium to continue. Exiting.." -ForegroundColor $RED
                exit 1
            }
            $myst_port = "-p $mysterium_first_port`:4449"
        }
        
        # Create mysterium data directory
        $mystDataDir = Join-Path $PWD "$mysterium_data_folder/node$i"
        if (-not (Test-Path $mystDataDir)) {
            New-Item -Path $mystDataDir -ItemType Directory -Force | Out-Null
        }
        
        # Start mysterium container
        $containerCmd = "docker run -d --name myst$UNIQUE_ID$i --cap-add=NET_ADMIN $NETWORK_TUN $LOGS_PARAM $DNS_VOLUME -v ${PWD}/$mysterium_data_folder/node$i`:/var/lib/mysterium-node --restart unless-stopped $myst_port mysteriumnetwork/myst:latest service --agreed-terms-and-conditions"
        $CONTAINER_ID = Invoke-Expression $containerCmd
        
        if ($LASTEXITCODE -eq 0) {
            $CONTAINER_ID | Out-File -FilePath $containers_file -Append
            "myst$UNIQUE_ID$i" | Out-File -FilePath $container_names_file -Append
            "http://127.0.0.1:$mysterium_first_port" | Out-File -FilePath $mysterium_file -Append
            $mysterium_first_port++
        }
        else {
            Write-Host "Failed to start container for Mysterium. Exiting.." -ForegroundColor $RED
            exit 1
        }
    }
    elseif (($MYSTERIUM -eq $true) -and $NETWORK_TUN) {
        if (-not $container_pulled) {
            Write-Host "Proxy for Mysterium is not supported at the moment due to ongoing issue. Please see https://github.com/xjasonlyu/tun2socks/issues/262 for more details. Ignoring Mysterium.." -ForegroundColor $RED
        }
    }
    else {
        if ((-not $container_pulled) -and ($ENABLE_LOGS -eq $true)) {
            Write-Host "Mysterium Node is not enabled. Ignoring Mysterium.." -ForegroundColor $RED
        }
    }

    # Continue with other containers (like Ebesucher, Adnade, etc.)
    # This would be the rest of the start_containers function from the bash script
    # converted to PowerShell...
}

# Main function to parse arguments and execute commands
function Main {
    param (
        [string]$Command
    )

    Show-Banner
    
    # Check if Docker is installed
    try {
        docker --version | Out-Null
    }
    catch {
        Write-Host "Docker is not installed or not in PATH. Please install Docker Desktop for Windows first." -ForegroundColor $RED
        exit 1
    }

    # Check if required files exist
    foreach ($file in $required_files) {
        if (-not (Test-Path $file)) {
            Write-Host "Required file $file does not exist. Please download it from the repository. Exiting.." -ForegroundColor $RED
            exit 1
        }
    }

    # Load properties from configuration file
    $config = @{}
    if (Test-Path $properties_file) {
        Get-Content $properties_file | ForEach-Object {
            $line = $_.Trim()
            if ($line -and -not $line.StartsWith('#') -and $line.Contains('=')) {
                $key, $value = $line.Split('=', 2)
                $config[$key.Trim()] = $value.Trim()
            }
        }
    }
    else {
        Write-Host "Configuration file $properties_file not found. Exiting.." -ForegroundColor $RED
        exit 1
    }

    # Convert config to PowerShell variables
    $config.GetEnumerator() | ForEach-Object {
        if ($_.Value -match "^'(.*)'$") {
            # Extract value from single quotes
            $value = $Matches[1]
        }
        else {
            $value = $_.Value
        }

        # Convert string true/false to boolean
        if ($value -eq "true") {
            $value = $true
        }
        elseif ($value -eq "false") {
            $value = $false
        }

        # Set variable in the script scope
        Set-Variable -Name $_.Key -Value $value -Scope Script
    }

    # Process command
    switch ($Command) {
        "--start" {
            # Start containers logic goes here
            # This would be the main start functionality from the bash script
            Write-Host "Starting Internet Income containers..." -ForegroundColor $GREEN
            
            # Here we would use proxies_file, if USE_PROXIES is true
            if ($USE_PROXIES -eq $true) {
                if (Test-Path $proxies_file) {
                    # Process proxies and start containers
                    Write-Host "Using proxies from $proxies_file" -ForegroundColor $GREEN
                    # Implementation would go here
                }
                else {
                    Write-Host "Proxies file $proxies_file not found but USE_PROXIES is set to true. Exiting.." -ForegroundColor $RED
                    exit 1
                }
            }
            # Implementation of starting all the containers...
        }
        
        "--delete" {
            # Delete containers logic goes here
            Write-Host "Deleting Internet Income containers..." -ForegroundColor $YELLOW
            
            # Here we would use files_to_be_removed and folders_to_be_removed
            Write-Host "Removing containers..." -ForegroundColor $YELLOW
            # Implementation of container deletion...
            
            Write-Host "Removing temporary files..." -ForegroundColor $YELLOW
            foreach ($file in $files_to_be_removed) {
                if (Test-Path $file) {
                    Remove-Item -Path $file -Force
                }
            }
            
            Write-Host "Removing temporary folders..." -ForegroundColor $YELLOW
            foreach ($folder in $folders_to_be_removed) {
                if (Test-Path $folder) {
                    Remove-Item -Path $folder -Force -Recurse
                }
            }
        }
        
        "--deleteBackup" {
            # Delete backup files logic goes here
            Write-Host "Deleting backup files and folders..." -ForegroundColor $YELLOW
            
            # Here we would use back_up_folders and back_up_files
            foreach ($file in $back_up_files) {
                if (Test-Path $file) {
                    Remove-Item -Path $file -Force
                    Write-Host "Deleted backup file: $file" -ForegroundColor $YELLOW
                }
            }
            
            foreach ($folder in $back_up_folders) {
                if (Test-Path $folder) {
                    Remove-Item -Path $folder -Force -Recurse
                    Write-Host "Deleted backup folder: $folder" -ForegroundColor $YELLOW
                }
            }
        }
        
        default {
            Write-Host "Usage: ./internetIncome.ps1 [--start|--delete|--deleteBackup]" -ForegroundColor $YELLOW
            Write-Host "  --start        : Start the containers" -ForegroundColor $YELLOW
            Write-Host "  --delete       : Delete the containers" -ForegroundColor $YELLOW
            Write-Host "  --deleteBackup : Delete backup files and folders" -ForegroundColor $YELLOW
        }
    }
}

# Entry point
if ($args.Count -eq 0) {
    # Show usage if no arguments provided
    Main
}
else {
    # Execute with provided command
    Main -Command $args[0]
} 