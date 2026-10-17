# Sanitized example: run from User Configuration > Logon (not SYSTEM)
[CmdletBinding()]
param([ValidateRange(0,180)][int]$MaxWaitSeconds=60,[ValidateRange(2,30)][int]$RetrySeconds=10,[switch]$DryRun)
$ErrorActionPreference='Stop'
$Computer=$env:COMPUTERNAME
$Identity=[Security.Principal.WindowsIdentity]::GetCurrent().Name
$AllowedComputers=@('PC-01','PC-02')
$AllowedUsers=1..10 | ForEach-Object { 'CORP\user{0:D2}' -f $_ }
if ($Computer -notin $AllowedComputers -or $Identity -notin $AllowedUsers) { exit 0 }
if (-not (Test-Path -LiteralPath 'C:\vixwin\vixwin.exe' -PathType Leaf)) { exit 0 }
$LogDir=Join-Path $env:LOCALAPPDATA 'ExampleCorp\VixWin'
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$Log=Join-Path $LogDir 'logon-launcher.log'
function Write-Log([string]$msg) {
  Add-Content -LiteralPath $Log -Encoding UTF8 -Value ('{0} [{1} / {2}] {3}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$Computer,$Identity,$msg)
}
$Script='\\ad.example.com\NETLOGON\ExampleCorp\VixWin\Set-VixWinUserSettings.example.ps1'
$Shares=@('\\nas01.ad.example.com\public','\\192.0.2.31\public')
$Deadline=(Get-Date).AddSeconds($MaxWaitSeconds)
try {
  Write-Log 'START: waiting for approved NAS mapping and script'
  do {
    $Ready=$false
    if (Test-Path -LiteralPath $Script -PathType Leaf) {
      $Disk=Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='Z:'" -ErrorAction SilentlyContinue
      $Ready=($null -ne $Disk -and $Disk.ProviderName -in $Shares -and
              (Test-Path -LiteralPath 'Z:\VXDATA' -PathType Container) -and
              -not (Get-Process -Name vixwin -ErrorAction SilentlyContinue))
    }
    if ($Ready) { break }
    if ((Get-Date) -ge $Deadline) { Write-Log 'PENDING: preflight unavailable'; exit 2 }
    Start-Sleep -Seconds $RetrySeconds
  } while ($true)
  if ($DryRun) { Write-Log 'DRY RUN: ready; no deployment'; exit 0 }
  & (Join-Path $PSHOME 'powershell.exe') -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script
  $Result=$LASTEXITCODE
  Write-Log "DEPLOY EXIT: $Result"
  exit $Result
} catch {
  Write-Log "ERROR: $($_.Exception.Message)"
  exit 1
}
