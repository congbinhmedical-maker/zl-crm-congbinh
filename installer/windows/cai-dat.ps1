# AXIS-ZALO - buoc cai dat sau khi giai nen
# Duoc bo cai (Setup.exe) goi tu dong. Co the chay lai bang tay neu can.
param([string]$Dir = (Split-Path -Parent (Split-Path -Parent $PSCommandPath)))

$ErrorActionPreference = 'Continue'
Set-Location $Dir
$Host.UI.RawUI.WindowTitle = 'AXIS-ZALO - Dang cai dat'

function Say($msg, $color = 'White') { Write-Host $msg -ForegroundColor $color }
function Fail($msg) {
  Say ''
  Say "LOI: $msg" 'Red'
  Say 'Chup man hinh cua so nay gui cho bo phan ky thuat.' 'Yellow'
  Read-Host 'Bam Enter de dong'
  exit 1
}

Say '=============================================='
Say '   AXIS-ZALO - CAI DAT' 'Cyan'
Say "   Thu muc: $Dir"
Say '=============================================='

# 1. Docker Desktop
Say '[1/5] Kiem tra Docker Desktop...'
# Docker Desktop co the cai cho moi nguoi (Program Files) hoac rieng 1 user (LocalAppData)
function FindDockerDesktop {
  $c = @((Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'))
  $c += Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Programs') -Filter 'Docker Desktop.exe' -Recurse -Depth 3 -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
  $c | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
}
$dd = FindDockerDesktop
if ($dd) {
  $dockerBin = Join-Path (Split-Path -Parent $dd) 'resources\bin'
  if ((Test-Path $dockerBin) -and ($env:Path -notlike "*$dockerBin*")) { $env:Path = "$dockerBin;$env:Path" }
}
$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
  Say ''
  Say '      May chua co Docker Desktop (phan nen bat buoc).' 'Yellow'
  Say '      Bo cai se TU TAI VA CAI Docker Desktop (khoang 500 MB, 10-20 phut),'
  Say '      sau do TU KHOI DONG LAI MAY va tu cai tiep phan mem.'
  Say '      Windows se hoi quyen quan tri (Yes) 1-2 lan: bam Yes.' 'Yellow'
  $ans = Read-Host '      Bam Enter de bat dau (go N roi Enter de huy)'
  if ($ans -match '^[nN]') { Fail 'Da huy. Cai Docker Desktop tai https://www.docker.com/products/docker-desktop roi chay lai bo cai.' }

  # a) WSL 2 (Docker can). Chi cai neu chua co.

  # b) Docker Desktop: thu winget truoc, khong duoc thi tai ban chinh thuc
  $installed = $false
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Say '      Dang cai Docker Desktop bang winget...'
    $p = Start-Process winget -ArgumentList 'install -e --id Docker.DockerDesktop --accept-package-agreements --accept-source-agreements' -Verb RunAs -Wait -PassThru
    $installed = [bool](FindDockerDesktop)
  }
  if (-not $installed) {
    $url = 'https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe'
    $file = Join-Path $env:TEMP 'DockerDesktopInstaller.exe'
    Say '      Dang tai Docker Desktop tu docker.com (khoang 500 MB)...'
    try { Start-BitsTransfer -Source $url -Destination $file -ErrorAction Stop }
    catch { Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing }
    if (-not (Test-Path $file)) { Fail 'Khong tai duoc Docker Desktop. Kiem tra Internet roi chay lai.' }
    Say '      Dang cai Docker Desktop...'
    Start-Process $file -ArgumentList 'install --quiet --accept-license --backend=wsl-2' -Verb RunAs -Wait
    $installed = [bool](FindDockerDesktop)
  }
  if (-not $installed) { Fail 'Cai Docker Desktop khong thanh cong. Cai tay tai https://www.docker.com/products/docker-desktop roi chay lai bo cai.' }

  # c) Tu chay tiep sau khi khoi dong lai
  $cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Dir `"$Dir`""
  Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'CongBinhZaloCRM' -Value $cmd
  Say ''
  Say '      Da cai xong Docker Desktop. CAN KHOI DONG LAI MAY.' 'Green'
  Say '      Sau khi bat lai may va dang nhap, cua so nay se tu mo va cai tiep.' 'Green'
  Read-Host '      Luu cong viec dang lam, roi bam Enter de khoi dong lai ngay'
  Restart-Computer -Force
  exit 0
}
# WSL 2 bat buoc cho Docker Desktop: kiem tra ca khi Docker da cai san.
# Luon goi ban 64-bit (Sysnative) phong khi script bi chay tu tien trinh 32-bit.
function SysExe($name) {
  $n = Join-Path $env:windir "Sysnative\$name"
  if (Test-Path $n) { return $n }
  return (Join-Path $env:windir "System32\$name")
}
$wsl = SysExe 'wsl.exe'
$wslOk = $false
if (Test-Path $wsl) { & $wsl --status *> $null; $wslOk = ($LASTEXITCODE -eq 0) }
if (-not $wslOk) {
  Say '      May chua bat WSL 2 (Docker can). Dang bat - Windows hoi quyen thi bam Yes...' 'Yellow'
  $done = $false
  if (Test-Path $wsl) {
    $p = Start-Process $wsl -ArgumentList '--install --no-distribution' -Verb RunAs -Wait -PassThru
    $done = ($p.ExitCode -eq 0)
  }
  if (-not $done) {
    $dism = SysExe 'dism.exe'
    $a = Start-Process $dism -ArgumentList '/online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart' -Verb RunAs -Wait -PassThru
    $b = Start-Process $dism -ArgumentList '/online /enable-feature /featurename:VirtualMachinePlatform /all /norestart' -Verb RunAs -Wait -PassThru
    # 3010 = thanh cong, can khoi dong lai
    $done = (@(0, 3010) -contains $a.ExitCode) -and (@(0, 3010) -contains $b.ExitCode)
  }
  if (-not $done) { Fail 'Khong bat duoc WSL 2. Mo PowerShell (Run as administrator) chay: wsl --install --no-distribution , khoi dong lai may roi chay lai bo cai.' }
  $cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Dir `"$Dir`""
  Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'CongBinhZaloCRM' -Value $cmd
  Say '      Da bat WSL 2. CAN KHOI DONG LAI MAY, sau do cua so nay tu cai tiep.' 'Green'
  Read-Host '      Luu cong viec dang lam, roi bam Enter de khoi dong lai ngay'
  Restart-Computer -Force
  exit 0
}
function DockerOk { cmd /c 'docker info >nul 2>&1'; return ($LASTEXITCODE -eq 0) }
if (-not (DockerOk)) {
  Say '      Docker chua chay, dang mo Docker Desktop...' 'Yellow'
  $exe = FindDockerDesktop
  if ($exe) { Start-Process $exe }
  $ok = $false
  for ($i = 0; $i -lt 120; $i++) {
    Start-Sleep -Seconds 5
    if (DockerOk) { $ok = $true; break }
  }
  if (-not $ok) { Fail 'Docker Desktop khong khoi dong duoc sau 10 phut. Mo Docker Desktop bang tay, doi bieu tuong chuyen xanh, roi chay lai.' }
}
Say '      OK' 'Green'

# 2. File cau hinh .env voi mat khau ngau nhien (chi tao lan dau)
Say '[2/5] Tao cau hinh va mat khau...'
function RandHex([int]$bytes) {
  $b = New-Object byte[] $bytes
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b)
  -join ($b | ForEach-Object { $_.ToString('x2') })
}
$envFile = Join-Path $Dir '.env'
$passFile = Join-Path $Dir 'MAT-KHAU-DANG-NHAP.txt'
if (-not (Test-Path $envFile)) {
  $db = RandHex 18; $minio = RandHex 18
  $admin = 'Cb@' + (RandHex 5)
  $lines = Get-Content (Join-Path $Dir '.env.demo')
  $map = @{
    'JWT_SECRET'               = (RandHex 32)
    'ENCRYPTION_KEY'           = (RandHex 32)
    'FB_TOKEN_ENC_KEY'         = (RandHex 32)
    'DB_PASSWORD'              = $db
    'DATABASE_URL'             = "postgresql://crmuser:$db@db:5432/zalocrm"
    'S3_SECRET_KEY'            = $minio
    'MINIO_ROOT_PASSWORD'      = $minio
    'BOOTSTRAP_ADMIN_PASSWORD' = $admin
  }
  $out = foreach ($l in $lines) {
    if ($l -match '^([A-Z_]+)=' -and $map.ContainsKey($Matches[1])) { "$($Matches[1])=$($map[$Matches[1]])" }
    elseif ($l -match '^#') { $null }
    else { $l }
  }
  [System.IO.File]::WriteAllText($envFile, (($out | Where-Object { $_ -ne $null }) -join "`n") + "`n", (New-Object System.Text.UTF8Encoding($false)))
  $txt = "AXIS-ZALO`r`nDia chi: http://localhost:3080`r`nTai khoan: 0900000000`r`nMat khau: $admin`r`n`r`nDang nhap xong hay doi mat khau ngay.`r`n"
  [System.IO.File]::WriteAllText($passFile, $txt, (New-Object System.Text.UTF8Encoding($false)))
  Say '      Da tao mat khau moi.' 'Green'
} else {
  Say '      Da co cau hinh tu lan cai truoc, giu nguyen.' 'Green'
}

# 3. Build va chay
Say '[3/5] Tai va dung phan mem (lan dau mat 5-15 phut, dung tat cua so)...'
docker compose up -d --build
if ($LASTEXITCODE -ne 0) { Fail 'docker compose khong chay duoc (xem dong loi phia tren).' }
Say '      OK' 'Green'

# 4. Cho phan mem san sang
Say '[4/5] Cho phan mem khoi dong...'
$ready = $false
for ($i = 0; $i -lt 60; $i++) {
  try {
    $r = Invoke-WebRequest -Uri 'http://localhost:3080/login' -UseBasicParsing -TimeoutSec 5
    if ($r.StatusCode -eq 200) { $ready = $true; break }
  } catch { }
  Start-Sleep -Seconds 5
}
if (-not $ready) { Fail 'Phan mem chua phan hoi sau 5 phut. Chay lenh: docker compose logs app --tail 50 trong thu muc cai dat de xem loi.' }
Say '      OK' 'Green'

# 5. Xong
Say '[5/5] Hoan tat!' 'Green'
Say ''
if (Test-Path $passFile) { Get-Content $passFile | ForEach-Object { Say "   $_" 'Cyan' } }
Say ''
Say "Mat khau duoc luu o: $passFile" 'Yellow'
Start-Process 'http://localhost:3080'
Read-Host 'Bam Enter de dong cua so'
