#!/usr/bin/env pwsh

# Script to update proxies and restart instances if proxies are updated in proxies.txt
$containers_file = "containernames.txt"
$proxies_file = "proxies.txt"
$tun_containers_file = "tuncontainers.txt"
$updated_proxies_file = "updatedproxies.txt"

# Remove any previous temp files
if (Test-Path $tun_containers_file) {
    Remove-Item $tun_containers_file -Force
}

if (Test-Path $updated_proxies_file) {
    Remove-Item $updated_proxies_file -Force
}

# Check for required files
if (-not (Test-Path $containers_file)) {
    Write-Host "$containers_file file does not exist. Exiting.."
    exit 1
}

if (-not (Test-Path $proxies_file)) {
    Write-Host "$proxies_file file does not exist. Exiting.."
    exit 1
}

# Remove carriage returns from proxies file (Windows equivalent of removing ^M)
$content = Get-Content -Path $proxies_file -Raw
$content = $content -replace "`r", ""
Set-Content -Path $proxies_file -Value $content -NoNewline

# Get tun containers and store them
Get-Content $containers_file | ForEach-Object {
    $container = $_
    # Execute the docker inspect command and redirect output to null
    docker inspect $container 2>&1 | Out-Null
    
    # Only process if container exists
    if ($LASTEXITCODE -eq 0) {
        $container_image = docker inspect --format='{{.Config.Image}}' $container
        if ($container_image -match "^xjasonlyu/tun2socks.*") {
            $container | Out-File -FilePath $tun_containers_file -Append
        }
    }
}

# Store formatted proxies in a new file
$i = 0
Get-Content $proxies_file | ForEach-Object {
    $line = $_
    if (($line -match '^[^#].*') -and ($line.Trim() -ne "")) {
        $i++
        $line | Out-File -FilePath $updated_proxies_file -Append
    }
}

# Check if files were created
if (-not (Test-Path $tun_containers_file)) {
    Write-Host "$tun_containers_file file does not exist. Exiting.."
    exit 1
}

if (-not (Test-Path $updated_proxies_file)) {
    Write-Host "$updated_proxies_file file does not exist. Exiting.."
    exit 1
}

# Match the number of containers with proxies
$containerCount = (Get-Content $tun_containers_file | Measure-Object).Count
$proxyCount = (Get-Content $updated_proxies_file | Measure-Object).Count

if ($containerCount -eq $proxyCount) {
    Write-Host "Updating Proxies"
    
    # Get containers and proxies and process them in parallel
    $containers = Get-Content $tun_containers_file
    $proxies = Get-Content $updated_proxies_file
    
    for ($i = 0; $i -lt $containers.Count; $i++) {
        $container_id = $containers[$i]
        $container_proxy = $proxies[$i]
        
        $container_image = docker inspect --format='{{.Config.Image}}' $container_id
        if ($container_image -match "^xjasonlyu/tun2socks.*") {
            # Escape forward slashes for sed command
            $escaped_proxy = $container_proxy -replace '/', '\/'
            
            # Update the proxy in the container
            $command = "sed -i `"`\#--proxy`\#s`\#.*`\#    --proxy ${escaped_proxy} \\\\\`\#`" entrypoint.sh"
            docker exec $container_id sh -c $command
        }
    }
}
else {
    Write-Host "Number of containers ($containerCount) do not match proxies ($proxyCount). Exiting.."
    exit 1
}

# Stop all containers
Write-Host "Stopping all containers..."
Get-Content $containers_file | ForEach-Object {
    $container = $_
    # Execute the docker inspect command and redirect output to null
    docker inspect $container 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        docker stop $container
    }
}

Write-Host "Waiting for 5 seconds before starting"
Start-Sleep -Seconds 5

# Restart all containers
Write-Host "Restarting Containers"
Get-Content $containers_file | ForEach-Object {
    $container = $_
    docker restart $container
}

Write-Host "Proxies updated successfully!" 