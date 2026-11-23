@echo off
title Cong Binh Zalo CRM
cd /d "%~dp0.."
docker info >nul 2>&1
if not errorlevel 1 goto run
echo Dang mo Docker Desktop, doi khoang 1 phut...
start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
:wait
timeout /t 5 /nobreak >nul
docker info >nul 2>&1
if errorlevel 1 goto wait
:run
echo Dang khoi dong Cong Binh Zalo CRM...
docker compose up -d
timeout /t 5 /nobreak >nul
start "" http://localhost:3080
