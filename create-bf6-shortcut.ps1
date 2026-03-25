#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Creates a desktop shortcut for the BF6 Chat Fix Launcher that auto-elevates to admin.
    Uses a Scheduled Task trick — the shortcut triggers a task that runs as admin,
    so no UAC prompt appears.
#>

$TaskName = 'BF6_ChatFix_Launcher'
$ScriptPath = Join-Path $PSScriptRoot 'launch-bf6-chatfix.ps1'
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$ShortcutPath = Join-Path $DesktopPath 'BF6 Chat Fix.lnk'
# --- CONFIGURE THIS: Set to your BF6 install path ---
$BF6Icon = 'C:\Program Files\EA Games\Battlefield 6\bf6.exe'

# --- Step 1: Create a Scheduled Task that runs the script as admin ---
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-ExecutionPolicy Bypass -WindowStyle Normal -File `"$ScriptPath`""
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest -LogonType Interactive
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 12)

$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "[*] Removed existing scheduled task" -ForegroundColor Cyan
}

Register-ScheduledTask -TaskName $TaskName -Action $action -Principal $principal -Settings $settings -Description 'BF6 Chat Fix - kills TextInputHost/ctfmon before launching BF6' | Out-Null
Write-Host "[+] Scheduled task created: $TaskName" -ForegroundColor Green

# --- Step 2: Create desktop shortcut that triggers the task ---
$WshShell = New-Object -ComObject WScript.Shell
$shortcut = $WshShell.CreateShortcut($ShortcutPath)
$shortcut.TargetPath = 'schtasks.exe'
$shortcut.Arguments = "/run /tn `"$TaskName`""
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.Description = 'Launch BF6 with chat input fix (auto-admin)'
$shortcut.WindowStyle = 7  # Minimized (hides the schtasks window)

if (Test-Path $BF6Icon) {
    $shortcut.IconLocation = "$BF6Icon,0"
}

$shortcut.Save()
Write-Host "[+] Desktop shortcut created: $ShortcutPath" -ForegroundColor Green
Write-Host ""
Write-Host "Done. Double-click 'BF6 Chat Fix' on your desktop to launch." -ForegroundColor Yellow
Write-Host "No UAC prompt will appear." -ForegroundColor Yellow
