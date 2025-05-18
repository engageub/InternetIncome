@echo off
echo Updating proxies...
docker container inspect internet-income >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo Error: internet-income container not found or not running
  pause
  exit /b 1
)

docker exec internet-income bash -c "cd /app && bash updateProxies.sh"
if %ERRORLEVEL% NEQ 0 (
  echo Error: Failed to update proxies
  pause
  exit /b %ERRORLEVEL%
)
echo.
echo Proxies have been updated.
pause 