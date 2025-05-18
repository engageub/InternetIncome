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
$files_to_be_removed = @($dns_resolver_file, $containers_file, $container_names_file, $networks_file, $mysterium_file, $ebesucher_file, $adnade_file, $adnade_containers_file, $firefox_containers_file, $chrome_containers_file, "container_commands.sh")
$folders_to_be_removed = @($adnade_data_folder, $firefox_data_folder, $firefox_profile_data, $earnapp_data_folder, $chrome_data_folder, $chrome_profile_data)
$back_up_folders = @($titan_data_folder, $network3_data_folder, $bitping_data_folder, $traffmonetizer_data_folder, $mysterium_data_folder)
$back_up_files = @($earnapp_file, $proxybase_file, $proxyrack_file)

$container_pulled = $false
$script:docker_in_docker_detected = $false # Using script: scope to avoid redefinition warning

# Mysterium and ebesucher first port
$mysterium_first_port = 2000
$ebesucher_first_port = 3000
$adnade_first_port = 4000

# Unique ID - generate 32 random hex characters
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

# Test for open ports
function Test-OpenPorts {
    param (
        [int]$StartPort,
        [int]$NumPorts = 1
    )
    
    $portRange = $StartPort..($StartPort + $NumPorts - 1)
    $openPorts = 0
    
    foreach ($port in $portRange) {
        try {
            $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $port)
            $listener.Start()
            $listener.Stop()
        }
        catch {
            $openPorts++
        }
    }
    
    while ($openPorts -gt 0) {
        $StartPort += $NumPorts
        $portRange = $StartPort..($StartPort + $NumPorts - 1)
        $openPorts = 0
        foreach ($port in $portRange) {
            try {
                $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $port)
                $listener.Start()
                $listener.Stop()
            }
            catch {
                $openPorts++
            }
        }
    }
    
    return $StartPort
}

# Start containers
function Start-Containers {
    param (
        [int]$Index,
        [string]$Proxy
    )
    
    $DNS_VOLUME = "-v ${PWD}/$dns_resolver_file`:/etc/resolv.conf:ro"
    
    if (-not $global:container_pulled) {
        # Create DNS resolver file
        "nameserver 8.8.8.8`nnameserver 8.8.4.4`nnameserver 1.1.1.1`nnameserver 1.0.0.1`nnameserver 9.9.9.9" | Out-File -FilePath $dns_resolver_file -Encoding ascii
        
        if (-not (Test-Path $dns_resolver_file)) {
            Write-Host "There is a problem creating resolver file. Exiting.." -ForegroundColor $RED
            exit 1
        }
    }
    
    if ($ENABLE_LOGS -ne $true) {
        $LOGS_PARAM = "--log-driver none"
        $TUN_LOG_PARAM = "silent"
    }
    else {
        $LOGS_PARAM = "--log-driver=json-file --log-opt max-size=100k"
        $TUN_LOG_PARAM = "debug"
    }
    
    # If using proxy, setup network and TUN containers
    if ($Index -and $Proxy) {
        $NETWORK_TUN = "--network=container:tun$UNIQUE_ID$Index"
        
        # Mysterium port setup if enabled
        if ($MYSTERIUM -eq $true) {
            $mysterium_first_port = Test-OpenPorts $mysterium_first_port 1
            if (-not ($mysterium_first_port -match '^\d+$')) {
                Write-Host "Problem assigning port $mysterium_first_port .." -ForegroundColor $RED
                Write-Host "Failed to start Mysterium node. Resolve or disable Mysterium to continue. Exiting.." -ForegroundColor $RED
                exit 1
            }
            $mysterium_port = "-p $mysterium_first_port`:4449 "
        }
        
        # Ebesucher port setup if enabled
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
        
        # Adnade port setup if enabled
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
        
        # Pull tun2socks image if not pulled yet
        if (-not $global:container_pulled) {
            docker pull xjasonlyu/tun2socks:v2.5.2
        }
        
        # Create container_commands.sh script file
        $container_commands_content = "#!/bin/sh"
        
        if ($USE_SOCKS5_DNS -eq $true) {
            $TUN_DNS_VOLUME = $DNS_VOLUME
        }
        elseif ($USE_DNS_OVER_HTTPS -eq $true) {
            $container_commands_content = @"
$container_commands_content
echo -e "options use-vc
nameserver 8.8.8.8
nameserver 8.8.4.4" > /etc/resolv.conf
ip rule add iif lo ipproto udp dport 53 lookup main
"@
        }
        else {
            $TUN_DNS_VOLUME = $DNS_VOLUME
            $container_commands_content = @"
$container_commands_content
ip rule add iif lo ipproto udp dport 53 lookup main
"@
        }
        
        $container_commands_content | Out-File -FilePath "container_commands.sh" -Encoding ascii
        
        # Format the proxy string according to type
        if ($Proxy -match "^socks5://") {
            $proxyType = "SOCKS5"
            $proxyServer = $Proxy -replace "^socks5://", ""
        }
        elseif ($Proxy -match "^http://") {
            $proxyType = "HTTP"
            $proxyServer = $Proxy -replace "^http://", ""
        }
        else {
            Write-Host "Unknown proxy type for $Proxy. Format should be socks5://ip:port or http://ip:port. Exiting.." -ForegroundColor $RED
            exit 1
        }
        
        $containerCmd = "docker run -d --rm --name tun$UNIQUE_ID$Index $LOGS_PARAM $TUN_DNS_VOLUME $combined_ports --cap-add=NET_ADMIN --device=/dev/net/tun --entrypoint=/bin/sh xjasonlyu/tun2socks:v2.5.2 -c `"chmod +x /etc/container_commands.sh && /etc/container_commands.sh && tun2socks -device tun0 -proxy $Proxy -loglevel $TUN_LOG_PARAM`""
        
        try {
            $CONTAINER_ID = Invoke-Expression $containerCmd
            $CONTAINER_ID | Out-File -FilePath $containers_file -Append
            "tun$UNIQUE_ID$Index" | Out-File -FilePath $container_names_file -Append
        }
        catch {
            Write-Host "Failed to start container for tun2socks. Exiting.." -ForegroundColor $RED
            exit 1
        }
    }
    
    # Start Mysterium container
    if ($MYSTERIUM -eq $true) {
        if ($NETWORK_TUN) {
            Write-Host "Starting Mysterium container.." -ForegroundColor $GREEN
            Write-Host "Copy the following node url and paste in your browser" -ForegroundColor $GREEN
            Write-Host "You will also find the urls in the file $mysterium_file in the same folder" -ForegroundColor $GREEN
            
            if (-not $global:container_pulled) {
                docker pull mysteriumnetwork/myst:latest
            }
            
            if (-not $Proxy) {
                $mysterium_first_port = Test-OpenPorts $mysterium_first_port 1
                if (-not ($mysterium_first_port -match '^\d+$')) {
                    Write-Host "Problem assigning port $mysterium_first_port .." -ForegroundColor $RED
                    Write-Host "Failed to start Mysterium node. Resolve or disable Mysterium to continue. Exiting.." -ForegroundColor $RED
                    exit 1
                }
                $myst_port = "-p $mysterium_first_port`:4449"
            }
            
            # Create mysterium data directory
            $mystDataDir = Join-Path $PWD "$mysterium_data_folder/node$Index"
            if (-not (Test-Path $mystDataDir)) {
                New-Item -Path $mystDataDir -ItemType Directory -Force | Out-Null
            }
            
            # Start mysterium container
            # Build docker command arguments as an array
            $dockerArgs = @(
                "run",
                "-d",
                "--name", "myst$UNIQUE_ID$Index",
                "--cap-add=NET_ADMIN"
            )
            
            # Add network parameters if defined
            if ($NETWORK_TUN) {
                $dockerArgs += $NETWORK_TUN
            }
            
            # Add logs parameter if defined
            if ($LOGS_PARAM) {
                $dockerArgs += $LOGS_PARAM
            }
            
            # Add DNS volume if defined
            if ($DNS_VOLUME) {
                $dockerArgs += $DNS_VOLUME
            }
            
            # Add the remaining arguments
            $dockerArgs += @(
                "-v", "${PWD}/$mysterium_data_folder/node$Index`:/var/lib/mysterium-node",
                "--restart", "unless-stopped"
            )
            
            # Add port mapping if defined
            if ($myst_port) {
                $dockerArgs += $myst_port.Split(" ")
            }
            
            # Add image and command
            $dockerArgs += @(
                "mysteriumnetwork/myst:latest",
                "service",
                "--agreed-terms-and-conditions"
            )
            
            try {
                $CONTAINER_ID = & docker $dockerArgs
                $CONTAINER_ID | Out-File -FilePath $containers_file -Append
                "myst$UNIQUE_ID$Index" | Out-File -FilePath $container_names_file -Append
                "http://127.0.0.1:$mysterium_first_port" | Out-File -FilePath $mysterium_file -Append
                $script:mysterium_first_port++
            }
            catch {
                Write-Host "Failed to start container for Mysterium. Exiting.." -ForegroundColor $RED
                exit 1
            }
        }
        elseif (($MYSTERIUM -eq $true) -and $NETWORK_TUN) {
            if (-not $global:container_pulled) {
                Write-Host "Proxy for Mysterium is not supported at the moment due to ongoing issue. Please see https://github.com/xjasonlyu/tun2socks/issues/262 for more details. Ignoring Mysterium.." -ForegroundColor $RED
            }
        }
        else {
            if ((-not $global:container_pulled) -and ($ENABLE_LOGS -eq $true)) {
                Write-Host "Mysterium Node is not enabled. Ignoring Mysterium.." -ForegroundColor $RED
            }
        }
    }
    
    # Starting Earnapp container
    if ($EARNAPP -eq $true) {
        Write-Host "Starting Earnapp container.." -ForegroundColor $GREEN
        Write-Host "Copy the following node url and paste in your earnapp dashboard" -ForegroundColor $GREEN
        Write-Host "You will also find the urls in the file $earnapp_file in the same folder" -ForegroundColor $GREEN
        
        # Generate random ID for Earnapp
        $foundUnique = $false
        $attemptCount = 0
        $RANDOM_ID = ""
        
        while (-not $foundUnique -and $attemptCount -lt 500) {
            $RANDOM_ID = -join ((48..57) + (97..102) | Get-Random -Count 32 | ForEach-Object { [char]$_ })
            
            if (Test-Path $earnapp_file) {
                $content = Get-Content $earnapp_file
                if ($content -notcontains $RANDOM_ID) {
                    $foundUnique = $true
                }
            }
            else {
                $foundUnique = $true
            }
            
            $attemptCount++
        }
        
        if ($attemptCount -ge 500) {
            Write-Host "Unique UUID cannot be generated for Earnapp. Exiting.." -ForegroundColor $RED
            exit 1
        }
        
        $date_time = Get-Date -Format "MM/dd/yy HH:mm:ss"
        
        if (-not $global:container_pulled) {
            docker pull fazalfarhan01/earnapp:lite
        }
        
        # Create Earnapp data directory
        $earnappDataDir = Join-Path $PWD "$earnapp_data_folder/data$Index"
        if (-not (Test-Path $earnappDataDir)) {
            New-Item -Path $earnappDataDir -ItemType Directory -Force | Out-Null
        }
        
        # Check if UUID exists in the earnapp file
        $uuid = ""
        if (Test-Path $earnapp_file) {
            $lines = Get-Content $earnapp_file
            if ($Index -le $lines.Count) {
                $line = $lines[$Index - 1]
                if ($line -match "https://earnapp.com/r/([a-zA-Z0-9-]+)") {
                    $uuid = $Matches[1]
                }
            }
        }
        
        if (-not $uuid) {
            Write-Host "UUID does not exist, creating UUID"
            $uuid = "sdk-node-$RANDOM_ID"
            "$date_time https://earnapp.com/r/$uuid" | Out-File -FilePath $earnapp_file -Append
        }
        
        # Start Earnapp container
        try {
            # Build docker command arguments as an array for Earnapp
            $dockerArgs = @(
                "run",
                "-d",
                "--health-interval=24h",
                "--name", "earnapp$UNIQUE_ID$Index"
            )
            
            # Add logs parameter if defined
            if ($LOGS_PARAM) {
                $dockerArgs += $LOGS_PARAM
            }
            
            # Add DNS volume if defined
            if ($DNS_VOLUME) {
                $dockerArgs += $DNS_VOLUME
            }
            
            # Add restart policy
            $dockerArgs += @("--restart=always")
            
            # Add network parameters if defined
            if ($NETWORK_TUN) {
                $dockerArgs += $NETWORK_TUN
            }
            
            # Add the volume and environment variable
            $dockerArgs += @(
                "-v", "${PWD}/$earnapp_data_folder/data$Index`:/etc/earnapp",
                "-e", "EARNAPP_UUID=$uuid",
                "fazalfarhan01/earnapp:lite"
            )
            
            $CONTAINER_ID = & docker $dockerArgs
            $CONTAINER_ID | Out-File -FilePath $containers_file -Append
            "earnapp$UNIQUE_ID$Index" | Out-File -FilePath $container_names_file -Append
        }
        catch {
            Write-Host "Failed to start container for Earnapp. Exiting.." -ForegroundColor $RED
            exit 1
        }
    }
    else {
        if ((-not $global:container_pulled) -and ($ENABLE_LOGS -eq $true)) {
            Write-Host "Earnapp is not enabled. Ignoring Earnapp.." -ForegroundColor $RED
        }
    }
    
    # Additional containers can be added here: Ebesucher, Adnade, BitPing, Repocket, etc.
    # based on the Linux script pattern
    
    $global:container_pulled = $true
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
            Write-Host "Starting Internet Income containers..." -ForegroundColor $GREEN
            
            # Here we would use proxies_file, if USE_PROXIES is true
            if ($USE_PROXIES -eq $true) {
                if (Test-Path $proxies_file) {
                    # Process proxies and start containers
                    Write-Host "Using proxies from $proxies_file" -ForegroundColor $GREEN
                    
                    # Remove any carriage returns from proxies file
                    (Get-Content $proxies_file) | ForEach-Object { $_ -replace "`r", "" } | Set-Content $proxies_file
                    
                    $i = 0
                    foreach ($line in (Get-Content $proxies_file)) {
                        if ($line -match "^[^#].*") {
                            $i++
                            Start-Containers -Index $i -Proxy $line
                        }
                    }
                }
                else {
                    Write-Host "Proxies file $proxies_file not found but USE_PROXIES is set to true. Exiting.." -ForegroundColor $RED
                    exit 1
                }
            }
            else {
                Write-Host "USE_PROXIES is disabled, using direct internet connection..." -ForegroundColor $RED
                Start-Containers
            }
        }
        
        "--delete" {
            # Delete containers logic goes here
            Write-Host "Deleting Internet Income containers..." -ForegroundColor $YELLOW
            
            # Here we would use files_to_be_removed and folders_to_be_removed
            Write-Host "Removing containers..." -ForegroundColor $YELLOW
            # Implementation of container deletion...
            if (Test-Path $container_names_file) {
                $containerNames = Get-Content $container_names_file
                foreach ($containerName in $containerNames) {
                    try {
                        Write-Host "Stopping container: $containerName" -ForegroundColor $YELLOW
                        docker stop $containerName 2>$null
                        
                        Write-Host "Removing container: $containerName" -ForegroundColor $GREEN
                        docker rm -f $containerName 2>$null
                    }
                    catch {
                        Write-Host "Failed to remove container: $containerName" -ForegroundColor $RED
                    }
                }
                Write-Host "All containers removed successfully" -ForegroundColor $GREEN
            }
            else {
                Write-Host "No container names file found. No containers to remove." -ForegroundColor $YELLOW
            }
            
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