Set-AzContext '<> Visual Studio Enterprise Subscription'
$Name = 'RemoteApp'
$Prefix = $Name -creplace '[^A-Z]'
$VerbosePreference = "Continue"
Register-AzResourceProvider -ProviderNamespace 'Microsoft.DesktopVirtualization'
$Params             = @{Location = 'NorthCentralUS'}
$RG                 = New-AzResourceGroup @Params -Name ($Name+'RG')  #$RG = Get-AzResourceGroup -Name RemoteAppRG
$Params            += @{ResourceGroupName  = $RG.ResourceGroupName }

$CustomRdpProperty = "targetisaadjoined:i:1;drivestoredirect:s:;audiomode:i:0;videoplaybackmode:i:0;redirectclipboard:i:1;redirectprinters:i:0;
    devicestoredirect:s:; redirectcomports:i:0;redirectsmartcards:i:0;usbdevicestoredirect:s:;enablecredsspsupport:i:1;redirectwebauthn:i:1; use multimon:i:0;
    enablerdsaadauth:i:1;autoreconnection enabled:i:1;bandwidthautodetect:i:1;networkautodetect:i:1;compression:i:1; audiocapturemode:i:0;
    encode redirected video capture:i:1;camerastoredirect:s:;redirectlocation:i:0;keyboardhook:i:2"


# -PreferredAppGroupType determines if you can do desktop or Remote app on the pool. And the same VM can't be joined to multiple hosts.
$PoolParams = @{HostPoolType ='Pooled'; MaxSessionLimit ="3"; LoadBalancerType = 'BreadthFirst'; PreferredAppGroupType='RailApplications'}
$NameParams = @{Name = 'RAPool' ; FriendlyName= 'RAPool'; Description = "RemoteApp Host Pool for $Name PoC"}
$Pool = New-AzWvdHostPool @Params @PoolParams @NameParams -CustomRdpProperty $CustomRdpProperty -StartVMOnConnect

#Params to explore
#-AgentUpdateMaintenanceWindow -AgentUpdateType -AgentUpdateMaintenanceWindowTimeZone -AgentUpdateUseSessionHostLocalTime -IdentityType -SsoClientId


#$Pool = Get-AzWvdHostPool -ResourceGroupName $RG.ResourceGroupName



$RDPParams= @{Name= ($Prefix+'RdpRule'); Description= 'Allow RDP'; Access= 'Allow'; Protocol= 'Tcp'; Direction= 'Inbound'; SourcePortRange= '*'; DestinationPortRange= '3389'}
$RDPRule  = New-AzNetworkSecurityRuleConfig @RDPParams  -Priority 200 -SourceAddressPrefix '<>' -DestinationAddressPrefix VirtualNetwork
$NSG      = New-AzNetworkSecurityGroup @Params -Name ($Prefix+'NSG') -SecurityRules $RDPRule
$Subnet   = New-AzVirtualNetworkSubnetConfig -Name Default -AddressPrefix 192.168.0.0/29 -NetworkSecurityGroup $NSG
$Vnet     = New-AzVirtualNetwork @Params -Name ($Prefix+'VN') -AddressPrefix 192.168.0.0/28 -Subnet $Subnet
$PIP      = New-AzPublicIpAddress @Params -Name ($Prefix+'PIP') -AllocationMethod Dynamic -Sku Basic -DomainNameLabel $Name.ToLower()
$NIC      = New-AzNetworkInterface @Params -Name ($Prefix+'VmNic') -SubnetId $Vnet.Subnets[0].Id -PublicIpAddressId $PIP.Id -EnableAcceleratedNetworking

# -SecurityType Standard in VM config was needed to deploy ARM [-Offer 'windows11preview-arm64']. But ARM doesn't have any AVD images yet
#Register-AzProviderFeature -FeatureName UseStandardSecurityType -ProviderNamespace 'Microsoft.Compute'


$cred     = New-Object System.Management.Automation.PSCredential "<>",$(ConvertTo-SecureString '<>' -asplaintext -force)
#Identity to system assigned. Needed for Entra join
$vmConfig = New-AzVMConfig -VMName ($Prefix+'VM') -VMSize 'Standard_E4as_v6' -IdentityType SystemAssigned -LicenseType 'Windows_Client'|
            Set-AzVMOperatingSystem -Windows -ComputerName ($Prefix+'VM') -Credential $cred -TimeZone 'Central Standard Time' -ProvisionVMAgent -EnableAutoUpdate|
            Set-AzVMSourceImage -PublisherName microsoftwindowsdesktop -Offer 'windows-11' -Skus 'win11-24h2-avd' -Version latest|
            Set-AzVMOSDisk -Name ($Prefix+'VmMd') -Caching ReadWrite -CreateOption FromImage|
            Add-AzVMNetworkInterface -Id $NIC.Id|Set-AzVMBootDiagnostic -ResourceGroupName $RG.ResourceGroupName -Enable
New-AzVM @Params -VM $vmConfig

$vm = Get-AzVM -ResourceGroupName $RG.ResourceGroupName



#region Entra join with Intune enrollment.  #Entra Login works  after this and the device shows up under Devices in Entra and Intune Admin center
#Add AADLoginForWindows extension WITH Intune mdmId to trigger Entra join + Intune auto-enrollment
#    mdmId '0000000a-0000-0000-c000-000000000000' is the Intune MDM app GUID used by the extension.

$EntraJoinParams = @{Publisher = 'Microsoft.Azure.ActiveDirectory'; ExtensionType= 'AADLoginForWindows'; Name ='AADLoginForWindows';TypeHandlerVersion ='1.0' }
$aadSettings = @{ mdmId = "0000000a-0000-0000-c000-000000000000" } | ConvertTo-Json

Set-AzVMExtension -ResourceGroupName $RG.ResourceGroupName -VMName $vm.Name @EntraJoinParams -SettingString $aadSettings
New-AzRoleAssignment -Scope $vm.Id -RoleDefinitionName 'Virtual Machine Administrator Login' -SignInName $(Get-AzContext).Account.Id #Entra Login works
<#RequestId IsSuccessStatusCode StatusCode ReasonPhrase
--------- ------------------- ---------- ------------
                         True         OK
#>

Restart-AzVM -ResourceGroupName $RG.ResourceGroupName -Name $vm.Name
#endregion




#region PS7 and module installation works. But not winget.
#Worked
$script = @'
iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"
'@
#Worked
$script = @'
& "C:\Program Files\PowerShell\7\pwsh.exe" -NoLogo -NoProfile -Command "`$PSVersionTable"
'@


#Worked
$script = @'
& "C:\Program Files\PowerShell\7\pwsh.exe" -NoLogo -NoProfile -Command @"
Register-PSResourceRepository -Name MAR -Uri 'https://mcr.microsoft.com' -ApiVersion ContainerRegistry  -Verbose
Install-PSResource -Name Az.Compute,Az.Network,Az.Resources,Az.Storage -Repository MAR -Scope AllUsers -TrustRepository -Verbose
"@
'@

$result = Invoke-AzVMRunCommand -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -CommandId 'RunPowerShellScript' -ScriptString $script -Verbose
$result.Value.Message
#endregion






#region  in RDP : V2. After redeploying
iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"

Install-PSResource Microsoft.WinGet.Client -Repository PSGallery -TrustRepository -AcceptLicense -Scope AllUsers  #In PS7
Install-WinGetPackage -Id Microsoft.WindowsTerminal -Scope Any -Verbose

$token= '<>'
Install-WinGetPackage -Id Microsoft.WindowsVirtualDesktopAgent -Scope Any -Custom "REGISTRATIONTOKEN=""$token""" -Verbose
Install-WinGetPackage -Id Microsoft.WindowsVirtualDesktopBootloader -Scope Any -Verbose

Restart-Computer

Get-CimInstance Win32_Product |? Name -Match 'remote'| Select Name,Version,Vendor
<# Name                                                        Version        Vendor
----                                                        -------        ------
Remote Desktop Services Infrastructure Agent                1.0.11986.2200 Microsoft Corporation
Remote Desktop Agent Boot Loader                            1.0.9023.1100  Microsoft Corporation
Remote Desktop Services Infrastructure Geneva Agent 46.24.3 46.24.3        Microsoft Corporation
Remote Desktop Services SxS Network Stack                   1.0.2505.08650 Microsoft Corporation
Remote Desktop Services Infrastructure Agent                1.0.11802.2200 Microsoft Corporation
#>

Get-WinGetVersion

#.\WVDAgentUrlTool.exe  #For troubleshooting
#endregion
Get-AzWvdSessionHost -ResourceGroupName $RG.ResourceGroupName -HostPoolName $Pool.Name  #Verify host pool registration



#region Workspace setup
#This '-FriendlyName' shows on the Windows app
$WorkSpaceParams = @{ FriendlyName = 'MyWorkspace'; Description = 'My Test Workspace'}  #ApplicationGroupReference = $DAppGroup.Id;
$WorkSpace = New-AzWvdWorkspace @Params @WorkSpaceParams -Name 'MyWorkspace'

$AppGroupParams = @{ FriendlyName = ('MyWorkspace'+$Name+'Group'); Description = 'My Test Workspace test Application group'}
$AppGroup = New-AzWvdApplicationGroup @Params @AppGroupParams -ApplicationGroupType RemoteApp -Name ($Name+'Group') -HostPoolArmPath $Pool.Id -ShowInFeed

$AppParams = @{ResourceGroupName = $RG.ResourceGroupName; GroupName = $AppGroup.Name; CommandLineSetting = 'Allow'; ShowInPortal = $true}
New-AzWvdApplication @AppParams -Name ($AppGroup.Name+ 'Notepad') -FilePath "C:\Windows\notepad.exe" -FriendlyName 'Notepad' -Description ($Name+'Notepad')


#Had to run this after.
#$appGroup = Get-AzWvdApplicationGroup -ResourceGroupName $RG.ResourceGroupName -Name 'VDPool-AvdEnt-D-C-01-AppGroup'
#$workspace = Get-AzWvdWorkspace -ResourceGroupName $RG.ResourceGroupName -Name 'VDPool-AvdEnt-D-C-01-Workspace'
#$workspace.ApplicationGroupReference
$updatedAppGroups = $workspace.ApplicationGroupReference + $AppGroup.Id | Select-Object -Unique
Update-AzWvdWorkspace -ResourceGroupName $RG.ResourceGroupName -Name $workspace.Name -ApplicationGroupReference $updatedAppGroups

#The app shows in user's feed after refreshing on the app
New-AzRoleAssignment -Scope $AppGroup.Id -RoleDefinitionName 'Desktop Virtualization User' -SignInName $(Get-AzContext).Account.Id

#endregion



#region Boot on Connect works after this
Connect-Entra -Scopes 'Application.Read.All'
$AvdSpn = Get-EntraServicePrincipal -Filter "displayName eq 'Azure Virtual Desktop'"   #9cdead84-a844-4324-93f2-b2e6bb768d07
#If you assign this role at any level lower than a subscription, such as the resource group, host pool, or VM, prevents Start VM on Connect from working properly.
New-AzRoleAssignment -Scope "/subscriptions/$((Get-AzContext).Subscription.Id)" -RoleDefinitionName 'Desktop Virtualization Power On Off Contributor' -ApplicationId $AvdSpn.AppId -Verbose
#endregion