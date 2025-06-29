#region DeployWindows11ArmVM

#region Variables
$Params   = @{Location = 'NorthCentralUS'; Verbose=$true}
$RG       = New-AzResourceGroup @Params -Name ($Name+'RG')
$Params  += @{ResourceGroupName  = $RG.ResourceGroupName }
#endregion

#region NetworkConfiguration
$RDPParams= @{Name= "$Name'RDPRule'"; Description= 'Allow RDP'; Access= 'Allow'; Protocol= 'Tcp'; Direction= 'Inbound'; SourcePortRange= '*'; DestinationPortRange= '3389'}
$RDPRule  = New-AzNetworkSecurityRuleConfig @RDPParams  -Priority 200 -SourceAddressPrefix <YourIP> -DestinationAddressPrefix VirtualNetwork
$NSG      = New-AzNetworkSecurityGroup @Params -Name $Name'NSG' -SecurityRules $RDPRule
$Subnet   = New-AzVirtualNetworkSubnetConfig -Name Default -AddressPrefix 192.168.0.0/29 -NetworkSecurityGroup $NSG 
$Vnet     = New-AzVirtualNetwork @Params -Name $Name'VN' -AddressPrefix 192.168.0.0/28 -Subnet $Subnet
$PIP      = New-AzPublicIpAddress @Params -Name $Name'PIP' -AllocationMethod Dynamic -Sku Basic -DomainNameLabel $Name.ToLower()
$NIC      = New-AzNetworkInterface @Params -Name $Name'NIC' -SubnetId $Vnet.Subnets[0].Id -PublicIpAddressId $PIP.Id -EnableAcceleratedNetworking
#endregion

#region VirtualMachineConfiguration
$cred     = New-Object System.Management.Automation.PSCredential "admin",$(ConvertTo-SecureString '<>' -asplaintext -force)
$vmConfig = New-AzVMConfig -VMName $Name'VM' -VMSize Standard_E4ps_v5 -LicenseType Windows_Client| 
            Set-AzVMOperatingSystem -Windows -ComputerName $Name'VM' -Credential $cred -TimeZone 'Central Standard Time' -ProvisionVMAgent -EnableAutoUpdate| 
            Set-AzVMSourceImage -PublisherName MicrosoftWindowsDesktop -Offer windows11preview-arm64 -Skus win11-22h2-ent  -Version latest|  
            Set-AzVMOSDisk -Name $Name'D' -Caching ReadWrite -CreateOption FromImage|    
            Add-AzVMNetworkInterface -Id $NIC.Id|Set-AzVMBootDiagnostic -ResourceGroupName $RG.ResourceGroupName -Enable   
#endregion 

#region DeploysVM
New-AzVM @Params -VM $vmConfig  #Deploys the VM
#endregion

#endregion

#region testRegion
test
#endRegion


#region blogname2

#region CodeSnippet
code
#endregion




#endregion
