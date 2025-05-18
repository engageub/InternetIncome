@echo off
echo Updating proxies...
docker exec internet-income bash -c "cd /app && bash updateProxies.sh"
echo.
echo Proxies have been updated.
pause 