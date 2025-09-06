
#Had to RDP with local admin and run manually
$script = @'
& "C:\Program Files\PowerShell\7\pwsh.exe" -NoLogo -NoProfile -Command @"
Install-PSResource Microsoft.WinGet.Client -Repository PSGallery -TrustRepository -Quiet -AcceptLicense
Repair-WinGetPackageManager
Install-WinGetPackage -Id Microsoft.WindowsTerminal -Scope Any -Verbose
"@
'@

#region Winget remotely. Doesn't work.
#https://github.com/microsoft/winget-cli/issues/3935

<#Winget: The term 'Winget' is not recognized as a name of a cmdlet, function, script file, or executable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
#>
$script = @'
& "C:\Program Files\PowerShell\7\pwsh.exe" -NoLogo -NoProfile -Command "Winget"
'@
<#Winget : The term 'Winget' is not recognized as the name of a cmdlet, function, script file, or operable program.
Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
#>
$script = @'
Winget
'@


$script = @'
& "C:\Program Files\PowerShell\7\pwsh.exe" -NoLogo -NoProfile -Command @"
$winget = Get-ChildItem "C:\Program Files\WindowsApps" -Filter winget.exe -Recurse -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -match 'Microsoft\.DesktopAppInstaller_.*(x64|arm64)__8wekyb3d8bbwe\\winget\.exe' } |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1 -Expand FullName

& $winget --version
"@
'@


$script = @'
Import-Module Microsoft.WinGet.Client
Get-WinGetVersion
'@



$script = @'
& "C:\Program Files\PowerShell\7\pwsh.exe" -NoProfile -Command "Install-WinGetPackage -Id Microsoft.WindowsVirtualDesktopBootloader -Scope Any -Verbose"
'@




$script = @'
Import-Module (Get-ChildItem 'C:\Program Files\PowerShell\Modules\*WinGet*\*\*.psd1').FullName
Get-WinGetVersion
'@

#https://github.com/microsoft/winget-cli/issues/3935
#Get-WinGetVersion doesn't work despite module loading since it's running in system context.
$script = @'
& "C:\Program Files\PowerShell\7\pwsh.exe" -NoLogo -NoProfile -Command @"
`$PSVersionTable
Import-Module Microsoft.WinGet.Client
Get-Module -ListAvailable *winget*
Microsoft.WinGet.Client\Get-WinGetVersion
"@
'@
#endregion





$result = Invoke-AzVMRunCommand -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -CommandId 'RunPowerShellScript' -ScriptString $script -Verbose
$result.Value.Message




