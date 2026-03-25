#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Quick fix — run this while BF6 is open and chat isn't working.
    Kills TextInputHost.exe immediately. Alt-tab back to BF6 and try chat again.
#>

$ti = Get-Process TextInputHost -ErrorAction SilentlyContinue
$ctf = Get-Process ctfmon -ErrorAction SilentlyContinue

if ($ti) {
    Stop-Process -Name TextInputHost -Force
    Write-Host "[+] Killed TextInputHost.exe (PID: $($ti.Id -join ', '))" -ForegroundColor Green
} else {
    Write-Host "[*] TextInputHost.exe not running" -ForegroundColor Cyan
}

if ($ctf) {
    Stop-Process -Name ctfmon -Force
    Write-Host "[+] Killed ctfmon.exe (PID: $($ctf.Id -join ', ')) - will auto-restart" -ForegroundColor Green
} else {
    Write-Host "[*] ctfmon.exe not running" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Alt-tab back to BF6 and try chat now." -ForegroundColor Yellow
Write-Host "If it works, use launch-bf6-chatfix.ps1 next time for automatic protection." -ForegroundColor Yellow
