@echo off
title Cong Binh Zalo CRM - Khoi phuc du lieu tu may cu
cd /d "%~dp0.."
if not exist backups\chuyen-may.dump goto thieu
if not exist backups\chuyen-may.env goto thieu
echo CANH BAO: du lieu hien tai tren may nay se bi thay bang du lieu may cu.
choice /m "Tiep tuc"
if errorlevel 2 exit /b 0
docker compose down
copy /y backups\chuyen-may.env .env >nul
docker compose up -d db
timeout /t 15 /nobreak >nul
docker compose exec -T db pg_restore -U crmuser -d zalocrm --clean --if-exists < backups\chuyen-may.dump
docker compose up -d
echo XONG. Dang nhap bang tai khoan cua may cu.
start "" http://localhost:3080
pause
exit /b 0
:thieu
echo Thieu file. Chep chuyen-may.dump va chuyen-may.env vao thu muc:
echo    %cd%\backups
pause
