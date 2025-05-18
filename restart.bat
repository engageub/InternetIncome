@echo off
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