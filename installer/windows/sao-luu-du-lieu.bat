@echo off
title Cong Binh Zalo CRM - Sao luu de chuyen may
cd /d "%~dp0.."
if not exist backups mkdir backups
echo Dang sao luu du lieu (phan mem phai dang chay)...
docker compose exec -T db pg_dump -U crmuser -Fc zalocrm > backups\chuyen-may.dump
if errorlevel 1 (
  echo LOI: khong sao luu duoc. Mo phan mem truoc roi chay lai.
  pause
  exit /b 1
)
copy /y .env backups\chuyen-may.env >nul
echo.
echo XONG. Chep 2 file sau sang may moi (USB hoac Drive rieng):
echo    %cd%\backups\chuyen-may.dump
echo    %cd%\backups\chuyen-may.env
echo File .env chua khoa ma hoa - KHONG gui qua Zalo/email.
pause
