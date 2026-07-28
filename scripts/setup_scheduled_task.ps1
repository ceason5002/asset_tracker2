# One-time setup: registers a Scheduled Task that runs the Asset Tracker
# app (via scripts\run_server.ps1) at system startup. Run this once from
# an elevated ("Run as Administrator") PowerShell window:
#
#   powershell -ExecutionPolicy Bypass -File "C:\Users\christopher.eason\asset_tracker\scripts\setup_scheduled_task.ps1"

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Users\christopher.eason\asset_tracker\scripts\run_server.ps1"'
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "christopher.eason" -LogonType S4U -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask -TaskName "AssetTrackerWebApp" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Runs the Asset Tracker Django app via waitress on port 8000" -Force

New-NetFirewallRule -DisplayName "Asset Tracker (8000)" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow -Profile Domain,Private -ErrorAction SilentlyContinue

Write-Output "Done. Scheduled task 'AssetTrackerWebApp' registered and firewall rule added."
