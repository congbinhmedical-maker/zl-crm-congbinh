@echo off
title Cong Binh Zalo CRM - Tat
cd /d "%~dp0.."
echo Dang tat Cong Binh Zalo CRM (du lieu van duoc giu)...
docker compose stop
echo Da tat.
timeout /t 3 /nobreak >nul
