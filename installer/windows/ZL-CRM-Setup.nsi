; Bo cai Cong Binh Zalo CRM cho Windows
; Build: makensis -DPAYLOAD=<thu muc ma nguon> -DOUTFILE=<file exe> ZL-CRM-Setup.nsi
Unicode true
!include "MUI2.nsh"
!include "LogicLib.nsh"

!ifndef PAYLOAD
  !error "Thieu -DPAYLOAD"
!endif
!ifndef OUTFILE
  !define OUTFILE "CongBinh-ZaloCRM-Setup.exe"
!endif
!define APPNAME "Công Bình Zalo CRM"
!define APPKEY "CongBinhZaloCRM"
!define VERSION "3.3.4-cb1"

Name "${APPNAME}"
OutFile "${OUTFILE}"
RequestExecutionLevel user
SetCompressor /SOLID lzma
InstallDir "C:\ZL-CRM"
BrandingText "Công Bình Medical"
VIProductVersion "3.3.4.1"
VIAddVersionKey "ProductName" "${APPNAME}"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "CompanyName" "Công Bình Medical"
VIAddVersionKey "LegalCopyright" "Apache-2.0 - xem LICENSE, NOTICE"
VIAddVersionKey "FileDescription" "Bộ cài ${APPNAME}"

!define MUI_ICON "congbinh.ico"
!define MUI_UNICON "congbinh.ico"
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "Cài đặt ${APPNAME}"
!define MUI_WELCOMEPAGE_TEXT "Phần mềm quản lý nhiều nick Zalo cho đội sales.$\r$\n$\r$\nNếu máy chưa có Docker Desktop (phần nền bắt buộc), bộ cài sẽ tự tải, tự cài, khởi động lại máy rồi cài tiếp.$\r$\n$\r$\nYÊU CẦU: Windows 10/11, ổ đĩa trống ít nhất 20 GB, có Internet.$\r$\n$\r$\nLần cài đầu mất 15–30 phút. Bấm Tiếp để chọn thư mục cài."
!define MUI_DIRECTORYPAGE_TEXT_TOP "Chọn ổ và thư mục cài. Mặc định là E:\ZL-CRM nếu máy có ổ E. Tránh thư mục Program Files."
!define MUI_FINISHPAGE_TITLE "Đã chép xong file"
!define MUI_FINISHPAGE_TEXT "Cửa sổ màu xanh đã dựng xong phần mềm và mở trình duyệt.$\r$\n$\r$\nTừ lần sau: bấm biểu tượng '${APPNAME}' ngoài màn hình.$\r$\nTài khoản và mật khẩu nằm trong file MAT-KHAU-DANG-NHAP.txt ở thư mục cài."

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Vietnamese"

Function .onInit
  ${If} ${FileExists} "E:\*.*"
    StrCpy $INSTDIR "E:\ZL-CRM"
  ${EndIf}
FunctionEnd

Section "Cài đặt" SecMain
  SetOutPath "$INSTDIR"
  File /r "${PAYLOAD}\*.*"
  SetOutPath "$INSTDIR\installer"
  File "congbinh.ico"
  File "cai-dat.ps1"
  File "mo-phan-mem.bat"
  File "tat-phan-mem.bat"
  File "sao-luu-du-lieu.bat"
  File "khoi-phuc-du-lieu.bat"
  SetOutPath "$INSTDIR"

  WriteUninstaller "$INSTDIR\go-cai-dat.exe"

  CreateShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\installer\mo-phan-mem.bat" "" "$INSTDIR\installer\congbinh.ico"
  CreateDirectory "$SMPROGRAMS\${APPNAME}"
  CreateShortCut "$SMPROGRAMS\${APPNAME}\Mở ${APPNAME}.lnk" "$INSTDIR\installer\mo-phan-mem.bat" "" "$INSTDIR\installer\congbinh.ico"
  CreateShortCut "$SMPROGRAMS\${APPNAME}\Tắt ${APPNAME}.lnk" "$INSTDIR\installer\tat-phan-mem.bat" "" "$INSTDIR\installer\congbinh.ico"
  CreateShortCut "$SMPROGRAMS\${APPNAME}\Sao lưu để chuyển máy.lnk" "$INSTDIR\installer\sao-luu-du-lieu.bat" "" "$INSTDIR\installer\congbinh.ico"
  CreateShortCut "$SMPROGRAMS\${APPNAME}\Khôi phục dữ liệu từ máy cũ.lnk" "$INSTDIR\installer\khoi-phuc-du-lieu.bat" "" "$INSTDIR\installer\congbinh.ico"
  CreateShortCut "$SMPROGRAMS\${APPNAME}\Mật khẩu đăng nhập.lnk" "$INSTDIR\MAT-KHAU-DANG-NHAP.txt"
  CreateShortCut "$SMPROGRAMS\${APPNAME}\Gỡ cài đặt.lnk" "$INSTDIR\go-cai-dat.exe"

  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPKEY}" "DisplayName" "${APPNAME}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPKEY}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPKEY}" "Publisher" "Công Bình Medical"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPKEY}" "DisplayIcon" "$INSTDIR\installer\congbinh.ico"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPKEY}" "UninstallString" "$\"$INSTDIR\go-cai-dat.exe$\""
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPKEY}" "InstallLocation" "$INSTDIR"

  DetailPrint "Đang dựng phần mềm trong cửa sổ PowerShell, vui lòng chờ..."
  ; Bo cai la tien trinh 32-bit: goi PowerShell 64-bit qua Sysnative de thay wsl.exe/dism.exe
  StrCpy $0 "$WINDIR\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
  ${IfNot} ${FileExists} "$0"
    StrCpy $0 "powershell.exe"
  ${EndIf}
  ExecWait '"$0" -NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\installer\cai-dat.ps1" -Dir "$INSTDIR"'
SectionEnd

Section "Uninstall"
  MessageBox MB_YESNO|MB_ICONEXCLAMATION "Xóa luôn TOÀN BỘ dữ liệu (tin nhắn, khách hàng, phiên đăng nhập Zalo)?$\r$\n$\r$\nCó = xóa sạch, không khôi phục được.$\r$\nKhông = giữ dữ liệu trong Docker và thư mục backups để cài lại sau." IDYES wipe
    nsExec::ExecToLog 'cmd /c cd /d "$INSTDIR" && docker compose down'
    Goto files
  wipe:
    nsExec::ExecToLog 'cmd /c cd /d "$INSTDIR" && docker compose down -v'
  files:
  Delete "$DESKTOP\${APPNAME}.lnk"
  RMDir /r "$SMPROGRAMS\${APPNAME}"
  RMDir /r "$INSTDIR\backend"
  RMDir /r "$INSTDIR\frontend"
  RMDir /r "$INSTDIR\docker"
  RMDir /r "$INSTDIR\installer"
  Delete "$INSTDIR\docker-compose.yml"
  Delete "$INSTDIR\.env.demo"
  Delete "$INSTDIR\go-cai-dat.exe"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPKEY}"
SectionEnd
