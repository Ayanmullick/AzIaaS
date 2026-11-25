#region DeployWindows11ArmVM

#region Variables
$Name,$Location = 'Win11Arm','centralus'
$Scope          = @{ResourceGroupName=($Name+'RG')}
$Params         = $Scope + @{Location=$Location}
#endregion

#region NetworkConfiguration
$RDPParams = @{Name=($Name+'RDPRule'); Description='Allow RDP'; Access='Allow'; Protocol='Tcp'; Direction='Inbound'; SourcePortRange='*'; DestinationPortRange='3389'}
$RDPRule   = New-AzNetworkSecurityRuleConfig @RDPParams -Priority 200 -SourceAddressPrefix '<YourIP>' -DestinationAddressPrefix VirtualNetwork
$NSG       = New-AzNetworkSecurityGroup @Params -Name ($Name+'NSG') -SecurityRules $RDPRule
$Subnet    = New-AzVirtualNetworkSubnetConfig -Name Default -AddressPrefix '192.168.0.0/29' -NetworkSecurityGroup $NSG
$VNet      = New-AzVirtualNetwork @Params -Name ($Name+'VN') -AddressPrefix '192.168.0.0/28' -Subnet $Subnet
$PIP       = New-AzPublicIpAddress @Params -Name ($Name+'PIP') -AllocationMethod Static -Sku Standard -DomainNameLabel $Name.ToLowerInvariant()
$NIC       = New-AzNetworkInterface @Params -Name ($Name+'NIC') -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PIP.Id -EnableAcceleratedNetworking
#endregion

#region VirtualMachineConfiguration
$Cred     = New-Object System.Management.Automation.PSCredential 'azuser',$(ConvertTo-SecureString '<>' -AsPlainText -Force)
$VMConfig = New-AzVMConfig -VMName ($Name+'VM') -VMSize Standard_E4ps_v7 -SecurityType TrustedLaunch -LicenseType Windows_Client -EnableSecureBoot $true -EnableVtpm $true |
            Set-AzVMOperatingSystem -Windows -ComputerName ($Name+'VM') -Credential $Cred -TimeZone 'Central Standard Time' -ProvisionVMAgent -EnableAutoUpdate |
            Set-AzVMSourceImage -PublisherName MicrosoftWindowsDesktop -Offer windows11preview-arm64 -Skus win11-26h2-ent -Version latest |
            Set-AzVMOSDisk -Name ($Name+'OS') -CreateOption FromImage -Caching ReadWrite -StorageAccountType StandardSSD_LRS |
            Add-AzVMNetworkInterface -Id $NIC.Id |
            Set-AzVMBootDiagnostic @Scope -Enable
#endregion

#region DeployAndVerifyVM
New-AzVM @Params -VM $VMConfig -IfNoneMatch '*'  # Protect an existing VM from updates

$AttestationSettings = @{AttestationConfig=@{MaaSettings=@{maaEndpoint=''; maaTenantName='GuestAttestation'}
    AscSettings=@{ascReportingEndpoint=''; ascReportingFrequency=''}; useCustomToken='false'; disableAlerts='false'}}
$AttestationParams   = @{VMName=$VMConfig.Name; Name='GuestAttestation'; Publisher='Microsoft.Azure.Security.WindowsAttestation'
    ExtensionType='GuestAttestation'; TypeHandlerVersion='1.0'; EnableAutomaticUpgrade=$true; Settings=$AttestationSettings}
Set-AzVMExtension @Params @AttestationParams

$VM                  = Get-AzVM @Scope -Name $VMConfig.Name
$VM.SecurityProfile | Select-Object SecurityType
$VM.SecurityProfile.UefiSettings | Select-Object SecureBootEnabled,VTpmEnabled
Get-AzVM @Scope -Name $VMConfig.Name -Status | Select-Object Name,OsName,OsVersion,Statuses
Get-AzVMExtension @Scope -VMName $VMConfig.Name -Name $AttestationParams.Name | Select-Object Name,ProvisioningState
#endregion

#endregion
