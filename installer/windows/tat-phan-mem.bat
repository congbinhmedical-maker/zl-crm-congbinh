@echo off
title AXIS-ZALO - Tat
cd /d "%~dp0.."
echo Dang tat AXIS-ZALO (du lieu van duoc giu)...
docker compose stop
echo Da tat.
timeout /t 3 /nobreak >nul
