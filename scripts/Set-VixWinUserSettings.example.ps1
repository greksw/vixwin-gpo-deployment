# VixWin Platinum 3.6.3 — SANITIZED EXAMPLE, NOT PRODUCTION-READY
# Private UI .reg exports and trusted SHA256 values are deliberately NOT supplied.
# Must run as the intended interactive USER, never SYSTEM.
[CmdletBinding()]
param([switch]$DryRun,[switch]$Force)
$ErrorActionPreference='Stop'
$Version='example-v4-review-required'
$Identity=[Security.Principal.WindowsIdentity]::GetCurrent().Name
$Computer=$env:COMPUTERNAME
$AllowedComputers=@('PC-01','PC-02')
$AllowedUsers=1..10 | ForEach-Object { 'CORP\user{0:D2}' -f $_ }
$Exe='C:\vixwin\vixwin.exe'
$Root='HKCU:\Software\Gendex\VixWin32'
$RegRoot='HKCU\Software\Gendex\VixWin32'
$Marker='HKCU:\Software\ExampleCorp\VixWin'
$UiRoot='\\ad.example.com\NETLOGON\ExampleCorp\VixWin\UI'
$LogDir=Join-Path $env:LOCALAPPDATA 'ExampleCorp\VixWin'
if ($Computer -notin $AllowedComputers -or $Identity -notin $AllowedUsers) {
  throw "SCOPE REJECTED: $Computer / $Identity"
}
if (-not (Test-Path -LiteralPath $Exe -PathType Leaf)) { throw "VixWin missing: $Exe" }
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$LogFile=Join-Path $LogDir 'deploy.log'
function Write-Log([string]$message) {
  $line='{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$Identity,$message
  Add-Content -LiteralPath $LogFile -Encoding UTF8 -Value $line
  Write-Host $line
}
$mutexName='Local\ExampleCorp-VixWin-Deploy-'+[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$mutex=New-Object System.Threading.Mutex($false,$mutexName)
$locked=$false
try {
  try { $locked=$mutex.WaitOne(0) }
  catch [System.Threading.AbandonedMutexException] { $locked=$true }
  if (-not $locked) { Write-Log 'PENDING: deployment already running'; exit 2 }
  if (Get-Process -Name 'vixwin' -ErrorAction SilentlyContinue) {
    Write-Log 'PENDING: VixWin is running'; exit 2
  }
  $disk=Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='Z:'" -ErrorAction SilentlyContinue
  $shares=@('\\nas01.ad.example.com\public','\\192.0.2.31\public')
  if ($null -eq $disk -or $disk.ProviderName -notin $shares -or
      -not (Test-Path -LiteralPath 'Z:\VXDATA' -PathType Container)) {
    Write-Log 'PENDING: unexpected/unavailable Z: or database folder'; exit 2
  }
  $hashes=[ordered]@{
    'Customize.reg'='0000000000000000000000000000000000000000000000000000000000000000'
    'Toolbar.reg'='0000000000000000000000000000000000000000000000000000000000000000'
    'Toolbox.reg'='0000000000000000000000000000000000000000000000000000000000000000'
    'UserInterface.reg'='0000000000000000000000000000000000000000000000000000000000000000'
  }
  if (@($hashes.Values | Where-Object { $_ -eq ('0'*64) }).Count -ne 0) {
    throw 'PUBLIC DEMO: replace deliberately invalid UI template SHA256 values in private configuration'
  }
  foreach ($file in $hashes.Keys) {
    $path=Join-Path $UiRoot $file
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing template: $file" }
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ine $hashes[$file]) {
      throw "UI SHA256 mismatch: $file"
    }
  }
  # Review every value against an actual working site profile. No DB is created.
  $entries=@(
    [pscustomobject]@{Section='Setup';Name='Config';Type='DWord';Value=1}
    [pscustomobject]@{Section='Setup';Name='Version';Type='String';Value='Platinum v3.6.3'}
    [pscustomobject]@{Section='Preferences';Name='Language';Type='String';Value='LNGRUSSK.DLL'}
    [pscustomobject]@{Section='Database';Name='Dbmode';Type='DWord';Value=1}
    [pscustomobject]@{Section='Database';Name='DatabaseReadOnly';Type='DWord';Value=1}
    [pscustomobject]@{Section='Database';Name='Dbdrive';Type='String';Value='Z'}
    [pscustomobject]@{Section='Database';Name='DefaultImageDrive';Type='String';Value='Z'}
    [pscustomobject]@{Section='Database';Name='LastPath';Type='String';Value='Z:\VXDATA'}
  )
  $fresh=-not (Test-Path -LiteralPath $Root)
  $markerExists=Test-Path -LiteralPath $Marker
  if ($fresh -and $markerExists) { throw 'HKCU marker exists but VixWin branch missing; manual review' }
  if (-not $fresh) {
    foreach ($section in @('Setup','Preferences','Database')) {
      if (-not (Test-Path -LiteralPath (Join-Path $Root $section))) {
        Write-Log "PENDING: existing profile lacks $section";exit 2
      }
    }
    $fixed=$entries | Where-Object { $_.Section -eq 'Setup' -or $_.Section -eq 'Preferences' -or
       ($_.Section -eq 'Database' -and $_.Name -in @('Dbmode','DatabaseReadOnly')) }
    foreach ($entry in $fixed) {
      $key=Get-Item -LiteralPath (Join-Path $Root $entry.Section)
      if ($key.GetValueNames() -notcontains $entry.Name -or
          $key.GetValueKind($entry.Name).ToString() -ne $entry.Type -or
          [string]$key.GetValue($entry.Name) -cne [string]$entry.Value) {
        Write-Log "PENDING: unexpected $($entry.Section)/$($entry.Name)";exit 2
      }
    }
  }
  $dbHealthy=$false;$uiHealthy=$false;$applied=''
  if (-not $fresh) {
    $db=Get-ItemProperty -LiteralPath (Join-Path $Root 'Database')
    $dbHealthy=($db.Dbdrive -ceq 'Z' -and $db.DefaultImageDrive -ceq 'Z' -and
                $db.LastPath -ceq 'Z:\VXDATA')
    $uiHealthy=@(@('Customize','Toolbar','Toolbox','UserInterface') |
      Where-Object { -not (Test-Path -LiteralPath (Join-Path $Root $_)) }).Count -eq 0
    if ($markerExists) {
      $applied=[string](Get-ItemProperty -LiteralPath $Marker -Name AppliedVersion -ErrorAction SilentlyContinue).AppliedVersion
    }
  }
  if (-not $Force -and -not $fresh -and $dbHealthy -and $uiHealthy -and $applied -eq $Version) {
    Write-Log 'SKIP: version marker and required settings healthy';exit 0
  }
  if ($DryRun) {
    Write-Log "DRY RUN: fresh=$fresh marker=$applied dbHealthy=$dbHealthy uiHealthy=$uiHealthy";exit 0
  }
  if (-not $fresh) {
    $backupDir=Join-Path $LogDir 'Backup'
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    $backup=Join-Path $backupDir ('VixWin-before-{0}.reg' -f (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
    & reg.exe export $RegRoot $backup /y | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'REG backup failed' }
    Write-Log "Backup: $backup"
  } else {
    New-Item -Path $Root -Force | Out-Null
    foreach ($section in @('Setup','Preferences','Database')) {
      New-Item -Path (Join-Path $Root $section) -Force | Out-Null
    }
    foreach ($entry in $entries) {
      New-ItemProperty -LiteralPath (Join-Path $Root $entry.Section) -Name $entry.Name -PropertyType $entry.Type -Value $entry.Value -Force | Out-Null
    }
    Write-Log 'Fresh HKCU initialized with eight values'
  }
  foreach ($file in $hashes.Keys) {
    & reg.exe import (Join-Path $UiRoot $file) | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "REG import failed: $file" }
    Write-Log "Imported: $file"
  }
  $dbPath=Join-Path $Root 'Database'
  foreach ($entry in ($entries | Where-Object { $_.Section -eq 'Database' -and $_.Name -in @('Dbdrive','DefaultImageDrive','LastPath') })) {
    New-ItemProperty -LiteralPath $dbPath -Name $entry.Name -PropertyType String -Value $entry.Value -Force | Out-Null
  }
  foreach ($entry in ($entries | Where-Object { $_.Section -eq 'Database' })) {
    $key=Get-Item -LiteralPath $dbPath
    if ($key.GetValueNames() -notcontains $entry.Name -or
        $key.GetValueKind($entry.Name).ToString() -ne $entry.Type -or
        [string]$key.GetValue($entry.Name) -cne [string]$entry.Value) {
      throw "Postcheck failed: $($entry.Name)"
    }
  }
  foreach ($section in @('Customize','Toolbar','Toolbox','UserInterface')) {
    if (-not (Test-Path -LiteralPath (Join-Path $Root $section))) { throw "Missing imported UI: $section" }
  }
  New-Item -Path $Marker -Force | Out-Null
  New-ItemProperty -LiteralPath $Marker -Name AppliedVersion -PropertyType String -Value $Version -Force | Out-Null
  New-ItemProperty -LiteralPath $Marker -Name AppliedAt -PropertyType String -Value (Get-Date -Format 's') -Force | Out-Null
  Write-Log 'SUCCESS: HKCU VixWin initialization completed'
} catch {
  Write-Log "ERROR: $($_.Exception.Message)"
  throw
} finally {
  if ($locked) { $mutex.ReleaseMutex() }
  $mutex.Dispose()
}
