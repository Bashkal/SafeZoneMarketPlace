@echo off
title SafeZone Marketplace Notification Worker
cd /d "%~dp0"
echo Starting SafeZone Marketplace Notification Worker...
echo.
node worker.js
pause
