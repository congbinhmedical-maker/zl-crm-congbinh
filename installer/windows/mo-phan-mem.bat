@echo off
title AXIS-ZALO
cd /d "%~dp0.."
docker info >nul 2>&1
if not errorlevel 1 goto run
echo Dang mo Docker Desktop, doi khoang 1 phut...
if exist "%ProgramFiles%\Docker\Docker\Docker Desktop.exe" start "" "%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
for /f "delims=" %%F in ('dir /b /s "%LOCALAPPDATA%\Programs\Docker Desktop.exe" 2^>nul') do start "" "%%F"
:wait
timeout /t 5 /nobreak >nul
docker info >nul 2>&1
if errorlevel 1 goto wait
:run
echo Dang khoi dong AXIS-ZALO...
docker compose up -d
timeout /t 5 /nobreak >nul
start "" http://localhost:3080
