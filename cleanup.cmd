@echo off
echo Cleaning up Internet Income containers...
docker-compose --profile cleanup up internet-income-cleanup
echo.
echo Cleanup completed. All containers have been removed.
pause 