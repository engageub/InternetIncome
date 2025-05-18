@echo off
REM Check if Docker is running
docker info >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo Error: Docker is not running. Please start Docker Desktop and try again.
  pause
  exit /b 1
)

REM Check if the container exists and is running
docker container inspect internet-income >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo Error: internet-income container not found or not running
  pause
  exit /b 1
)

SET OPTION=%1

IF "%OPTION%"=="--restartAdnade" (
    echo Restarting Adnade containers...
    docker exec internet-income bash -c "cd /app && bash restart.sh --restartAdnade"
    echo Adnade containers have been restarted.
) ELSE IF "%OPTION%"=="--restartChrome" (
    echo Restarting Chrome containers...
    docker exec internet-income bash -c "cd /app && bash restart.sh --restartChrome"
    echo Chrome containers have been restarted.
) ELSE IF "%OPTION%"=="--restartFirefox" (
    echo Restarting Firefox containers...
    docker exec internet-income bash -c "cd /app && bash restart.sh --restartFirefox"
    echo Firefox containers have been restarted.
) ELSE (
    echo Invalid option. Please use one of the following:
    echo --restartAdnade: Restart Adnade containers
    echo --restartChrome: Restart Chrome containers
    echo --restartFirefox: Restart Firefox containers
)

pause 