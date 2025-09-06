#region Intune
Start-Process 'ms-device-enrollment:?mode=mdm'  #Intune enrollment inside VM

dsregcmd /status
#MDM user scope  to AdminAgents in Entra Admin center

<#After Intune enrollment the 'Diagnostic Data' section in output shows 'Managed by MDM'
Diagnostic Data
DisplayNameUpdated : Managed by MDM
OsVersionUpdated : Managed by MDM
#>

# Last 50 MDM enrollment/management errors
Get-WinEvent -LogName 'Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin' -MaxEvents 50 |
  Sort TimeCreated | Format-Table TimeCreated, Id, LevelDisplayName, Message -Wrap

#endregion