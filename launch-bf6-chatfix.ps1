#Requires -RunAsAdministrator
<#
.SYNOPSIS
    BF6 Chat Fix Launcher - kills Windows Text Services Framework processes
    that intercept keyboard input when BF6 opens its in-game chat.

.DESCRIPTION
    Windows 11 24H2+ aggressively hooks text input fields via TextInputHost.exe
    and ctfmon.exe. When BF6 switches from Raw Input (gameplay) to a text control
    (chat), these processes consume keystrokes before the game sees them.

    This script:
    1. Kills TextInputHost.exe and ctfmon.exe
    2. Launches BF6
    3. Monitors and re-kills TextInputHost if Windows respawns it
    4. ctfmon.exe auto-restarts after BF6 exits

.NOTES
    Must run as Administrator to kill system processes.
    Both processes respawn naturally after BF6 closes.
#>

param(
    [switch]$DryRun
)

$ErrorActionPreference = 'SilentlyContinue'

$BF6Path = 'D:\Games\EA Games\Battlefield 6\bf6.exe'
$BF6Process = 'bf6'

function Write-Status($msg) { Write-Host "[*] $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "[+] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "[-] $msg" -ForegroundColor Red }

Write-Host ''
Write-Host '========================================' -ForegroundColor Magenta
Write-Host '  BF6 CHAT FIX LAUNCHER' -ForegroundColor Magenta
Write-Host '  Neutralizing Windows Input Hijack' -ForegroundColor Magenta
Write-Host '========================================' -ForegroundColor Magenta
Write-Host ''

if ($DryRun) {
    Write-Warn 'DRY RUN - no changes will be made'
    Write-Host ''
}

# --- Step 1: Kill TextInputHost.exe ---
$textInput = Get-Process TextInputHost -ErrorAction SilentlyContinue
if ($textInput) {
    Write-Status "TextInputHost.exe found (PID: $($textInput.Id))"
    if (-not $DryRun) {
        Stop-Process -Name TextInputHost -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        $check = Get-Process TextInputHost -ErrorAction SilentlyContinue
        if (-not $check) {
            Write-Success 'TextInputHost.exe killed'
        }
        else {
            Write-Warn 'TextInputHost.exe respawned immediately - will monitor'
        }
    }
}
else {
    Write-Success 'TextInputHost.exe not running'
}

# --- Step 2: Kill ctfmon.exe (it auto-restarts after session) ---
$ctfmon = Get-Process ctfmon -ErrorAction SilentlyContinue
if ($ctfmon) {
    Write-Status "ctfmon.exe found (PID: $($ctfmon.Id))"
    if (-not $DryRun) {
        Stop-Process -Name ctfmon -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        Write-Success 'ctfmon.exe killed (auto-restarts after gaming session)'
    }
}
else {
    Write-Success 'ctfmon.exe not running'
}

# --- Step 3: Launch BF6 ---
if (-not (Test-Path $BF6Path)) {
    Write-Fail "BF6 not found at: $BF6Path"
    Write-Fail 'Update the BF6Path variable in this script.'
    exit 1
}

Write-Host ''
Write-Status 'Launching BF6...'
if (-not $DryRun) {
    Start-Process $BF6Path
    Start-Sleep -Seconds 5
}

# --- Step 4: Monitor loop - keep TextInputHost dead while BF6 runs ---
Write-Status 'Monitoring for TextInputHost/ctfmon respawns (Ctrl+C to stop early)...'
Write-Host ''

$kills = 0
if (-not $DryRun) {
    while ($true) {
        $bf6Running = Get-Process $BF6Process -ErrorAction SilentlyContinue
        if (-not $bf6Running) {
            Write-Host ''
            Write-Status 'BF6 has exited'
            break
        }

        $tiRespawned = Get-Process TextInputHost -ErrorAction SilentlyContinue
        if ($tiRespawned) {
            Stop-Process -Name TextInputHost -Force -ErrorAction SilentlyContinue
            $kills++
            Write-Warn "TextInputHost respawned - killed again (total kills: $kills)"
        }

        $ctfRespawned = Get-Process ctfmon -ErrorAction SilentlyContinue
        if ($ctfRespawned) {
            Stop-Process -Name ctfmon -Force -ErrorAction SilentlyContinue
            $kills++
            Write-Warn "ctfmon respawned - killed again (total kills: $kills)"
        }

        Start-Sleep -Seconds 3
    }
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Magenta
Write-Host "  Session complete. Respawn kills: $kills" -ForegroundColor Magenta
Write-Host '  Input services will auto-restore.' -ForegroundColor Magenta
Write-Host '========================================' -ForegroundColor Magenta
Write-Host ''
