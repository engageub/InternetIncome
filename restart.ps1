#!/usr/bin/env pwsh

param (
    [Parameter(Mandatory=$false)]
    [string]$Command
)

# Process restart command
if ($Command -eq "--restartAdnade") {
    $firefox_profile_data = "firefoxprofiledata"
    $i = 0
    
    if (Test-Path "adnadecontainers.txt") {
        Get-Content "adnadecontainers.txt" | ForEach-Object {
            $container = $_
            $i++
            
            # Check if container exists by attempting to update it
            docker update --restart=no $container
            docker stop $container
            
            # Firefox with direct connection
            $basePath = Join-Path $PWD "firefox\adnadedata\data"
            if (Test-Path $basePath) {
                # Set permissions
                try {
                    # In Windows, we don't need chmod
                    # Instead we'll use Remove-Item and Copy-Item with -Force
                    
                    # Remove contents
                    Get-ChildItem -Path $basePath -Recurse | Remove-Item -Force -Recurse
                    
                    # Copy profile data
                    $sourceDir = Join-Path $PWD "firefox\$firefox_profile_data"
                    $destDir = Join-Path $PWD "adnadedata\data\"
                    Get-ChildItem -Path $sourceDir | Copy-Item -Destination $destDir -Recurse -Force
                    
                    # Update and start container
                    docker update --restart=always $container
                    Start-Sleep -Seconds 300
                    docker start $container
                }
                catch {
                    Write-Host "Error processing Firefox data: $($_.Exception.Message)"
                    continue
                }
            }
            
            # Check if data folder exists
            $dataPath = Join-Path $PWD "firefox\adnadedata\data$i"
            if (-not (Test-Path $dataPath)) {
                Write-Host "Folder data$i does not exist. Exiting.."
                exit 1
            }
            
            # Deleting data and starting containers
            try {
                # Remove contents
                Get-ChildItem -Path $dataPath -Recurse | Remove-Item -Force -Recurse
                
                # Copy profile data
                $sourceDir = Join-Path $PWD "firefox\$firefox_profile_data"
                $destDir = Join-Path $PWD "adnadedata\data$i\"
                Get-ChildItem -Path $sourceDir | Copy-Item -Destination $destDir -Recurse -Force
                
                # Update and start container
                docker update --restart=always $container
                if ($i -eq 1) {
                    Start-Sleep -Seconds 300
                }
                docker start $container
            }
            catch {
                Write-Host "Error processing Firefox data${i}: $($_.Exception.Message)"
                continue
            }
        }
    }
    else {
        Write-Host "adnadecontainers.txt file not found. Exiting.."
        exit 1
    }
}
elseif ($Command -eq "--restartChrome") {
    $chrome_profile_data = "chromeprofiledata"
    $chrome_data_folder = "chromedata"
    $i = 0
    
    if (Test-Path "chromecontainers.txt") {
        Get-Content "chromecontainers.txt" | ForEach-Object {
            $container = $_
            $i++
            
            # Check if container exists
            docker update --restart=no $container
            docker stop $container
            
            # Chrome with direct connection
            $basePath = Join-Path $PWD "chrome\$chrome_data_folder\data"
            if (Test-Path $basePath) {
                try {
                    # Remove contents (Windows equivalent of rm -rf)
                    Get-ChildItem -Path $basePath -Recurse | Remove-Item -Force -Recurse
                    
                    # In Windows we don't have direct chown equivalent
                    # Docker will handle ownership inside container
                    
                    # Copy profile data
                    $sourceDir = Join-Path $PWD "chrome\$chrome_profile_data"
                    Copy-Item -Path $sourceDir -Destination $basePath -Recurse -Force
                    
                    # Update and start container
                    docker update --restart=always $container
                    docker start $container
                }
                catch {
                    Write-Host "Error processing Chrome data: $($_.Exception.Message)"
                    continue
                }
            }
            
            # Check if data folder exists
            $dataPath = Join-Path $PWD "chrome\$chrome_data_folder\data$i"
            if (-not (Test-Path $dataPath)) {
                Write-Host "Folder data$i does not exist. Exiting.."
                exit 1
            }
            
            # Deleting data and starting containers
            try {
                # Remove contents
                Get-ChildItem -Path $dataPath -Recurse | Remove-Item -Force -Recurse
                
                # Copy profile data
                $sourceDir = Join-Path $PWD "chrome\$chrome_profile_data"
                Copy-Item -Path $sourceDir -Destination $dataPath -Recurse -Force
                
                # Update and start container
                docker update --restart=always $container
                docker start $container
            }
            catch {
                Write-Host "Error processing Chrome data${i}: $($_.Exception.Message)"
                continue
            }
        }
    }
    else {
        Write-Host "chromecontainers.txt file not found. Exiting.."
        exit 1
    }
}
elseif ($Command -eq "--restartFirefox") {
    $firefox_profile_data = "firefoxprofiledata"
    $i = 0
    
    if (Test-Path "firefoxcontainers.txt") {
        Get-Content "firefoxcontainers.txt" | ForEach-Object {
            $container = $_
            $i++
            
            # Check if container exists
            docker update --restart=no $container
            docker stop $container
            
            # Firefox with direct connection
            $basePath = Join-Path $PWD "firefox\firefoxdata\data"
            if (Test-Path $basePath) {
                try {
                    # Remove contents
                    Get-ChildItem -Path $basePath -Recurse | Remove-Item -Force -Recurse
                    
                    # Copy profile data
                    $sourceDir = Join-Path $PWD "firefox\$firefox_profile_data"
                    $destDir = Join-Path $PWD "firefoxdata\data\"
                    Get-ChildItem -Path $sourceDir | Copy-Item -Destination $destDir -Recurse -Force
                    
                    # Update and start container
                    docker update --restart=always $container
                    docker start $container
                }
                catch {
                    Write-Host "Error processing Firefox data: $($_.Exception.Message)"
                    continue
                }
            }
            
            # Check if data folder exists
            $dataPath = Join-Path $PWD "firefox\firefoxdata\data$i"
            if (-not (Test-Path $dataPath)) {
                Write-Host "Folder data$i does not exist. Exiting.."
                exit 1
            }
            
            # Deleting data and starting containers
            try {
                # Remove contents
                Get-ChildItem -Path $dataPath -Recurse | Remove-Item -Force -Recurse
                
                # Copy profile data
                $sourceDir = Join-Path $PWD "firefox\$firefox_profile_data"
                $destDir = Join-Path $PWD "firefoxdata\data$i\"
                Get-ChildItem -Path $sourceDir | Copy-Item -Destination $destDir -Recurse -Force
                
                # Update and start container
                docker update --restart=always $container
                docker start $container
            }
            catch {
                Write-Host "Error processing Firefox data${i}: $($_.Exception.Message)"
                continue
            }
        }
    }
    else {
        Write-Host "firefoxcontainers.txt file not found. Exiting.."
        exit 1
    }
}
else {
    Write-Host "Usage: ./restart.ps1 [--restartAdnade|--restartChrome|--restartFirefox]"
    Write-Host "  --restartAdnade  : Restart Adnade containers"
    Write-Host "  --restartChrome  : Restart Chrome containers"
    Write-Host "  --restartFirefox : Restart Firefox containers"
} 