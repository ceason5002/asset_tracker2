# Run once from an elevated ("Run as Administrator") PowerShell window:
#   powershell -ExecutionPolicy Bypass -File "C:\Users\christopher.eason\asset_tracker\scripts\add_firewall_rule.ps1"

netsh advfirewall firewall add rule name="Asset Tracker (8000)" dir=in action=allow protocol=TCP localport=8000 profile=domain,private
