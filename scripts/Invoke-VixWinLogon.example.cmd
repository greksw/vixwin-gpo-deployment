@echo off
%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "\\ad.example.com\NETLOGON\ExampleCorp\VixWin\Invoke-VixWinLogon.example.ps1"
exit /b %ERRORLEVEL%
