#region v2 of Create an Azure Firewall test environment  https://docs.microsoft.com/en-us/azure/firewall/scripts/sample-create-firewall-test
#This provisions one virtual machine as a jumpbox with a public IP and another one behind a firewall to test firewall routes.
$Name,$Env,$Location ='NvState','Tst','NorthCentralUS'
$RG                  = New-AzResourceGroup -Location $Location -Name ($Name+$Env+'RG') 
$Params              = @{ResourceGroupName  = $RG.ResourceGroupName; Location = $Location; Verbose=$true }

#Create Vnet. Configure subnets
$vNet = New-AzVirtualNetwork @Params -Name ($Name+$Env+'vNet')  -AddressPrefix 192.168.0.0/24
$Subnets= @{“AzureFirewallSubnet”=”192.168.0.0/26”;”JumpBoxSubnet”=”192.168.0.64/29”;”ServersSubnet”=”192.168.0.72/29”}
$Subnets.Keys | % { Add-AzVirtualNetworkSubnetConfig -Name $_ -AddressPrefix $Subnets.Item($_) -VirtualNetwork $vnet}
Set-AzVirtualNetwork -VirtualNetwork $vnet -Verbose

#create Public IP for jump VM and Fw
$FwPIP = New-AzPublicIpAddress @Params -Name ($Name+$Env+'FwPIP') -AllocationMethod Static -Sku Standard 
$JumpVMPIP = New-AzPublicIpAddress @Params -Name ($Name+$Env+'JumpVMPIP') -AllocationMethod Static -Sku Basic

# Create a network security group
$NSGRDPrule = New-AzNetworkSecurityRuleConfig -Name ($Name+$Env+'NSGRDPrule')  -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow
$NSG = New-AzNetworkSecurityGroup @Params  -Name ($Name+$Env+'NSG') -SecurityRules $NSGRDPrule

$Password = ConvertTo-SecureString '<>' -AsPlainText -Force            #User credentials for JumpBox and Server VMs
$cred = New-Object System.Management.Automation.PSCredential ("ayan", $Password)

$vNet= Get-AzVirtualNetwork -ResourceGroupName $RG.ResourceGroupName -Name ($Name+$Env+'vNet')

#Create jumpbox
$JumpVMNic = New-AzNetworkInterface @Params -Name ($Name+$Env+'JumpVMNic') -SubnetId $vnet.Subnets[1].Id -PublicIpAddressId $JumpVMPIP.Id -NetworkSecurityGroupId $NSG.Id  # Create a virtual network card and associate with jumpbox public IP address

$JumpVMConfig = New-AzVMConfig -VMName ($Name+$Env+'JmpVM') -VMSize Standard_D2_v4 -LicenseType Windows_Server|
                 Set-AzVMOperatingSystem -Windows -ComputerName ($Name+$Env+'JmpVM') -Credential $cred -TimeZone 'Central Standard Time' -ProvisionVMAgent -EnableAutoUpdate |
                 Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer windowsserver-gen2preview -Skus 2019-datacenter-gen2 -Version latest | 
                 Set-AzVMOSDisk -Name ($Name+$Env+'JmpVMD') -CreateOption FromImage|
                 Set-AzVMBootDiagnostic -Disable |
                 Add-AzVMNetworkInterface -Id $JumpVMNic.Id
New-AzVM @Params -VM $JumpVMConfig


#Create Server VM
$ServerVmNic = New-AzNetworkInterface -Name ($Name+$Env+'VMNic') @Params -SubnetId $vnet.Subnets[2].Id
$ServerVmConfig = New-AzVMConfig -VMName ($Name+$Env+'VM') -VMSize Standard_D2_v4 -LicenseType Windows_Server|
                  Set-AzVMOperatingSystem -Windows -ComputerName ($Name+$Env+'VM') -Credential $cred -TimeZone 'Central Standard Time' -ProvisionVMAgent -EnableAutoUpdate |
                  Set-AzVMSourceImage -PublisherName MicrosoftWindowsServer -Offer windowsserver-gen2preview -Skus 2019-datacenter-gen2 -Version latest |
                  Set-AzVMOSDisk -Name ($Name+$Env+'VMD') -CreateOption FromImage|
                  Set-AzVMBootDiagnostic -Disable|
                  Add-AzVMNetworkInterface -Id $ServerVmNic.Id
New-AzVM @Params -VM $ServerVmConfig




#region v1: Classic firewall creation. Add a rule to allow *microsoft.com
$Rule = New-AzFirewallApplicationRule -Name R1 -Protocol "http:80","https:443" -TargetFqdn "*microsoft.com"
$RuleCollection = New-AzFirewallApplicationRuleCollection -Name RC1 -Priority 100 -Rule $Rule -ActionType "Allow"
$Azfw = New-AzFirewall @Params -Name ($Name+$Env+'Fw') -VirtualNetworkName $vnet.Name -PublicIpName $FwPIP.Name -SkuTier Standard -ApplicationRuleCollection $RuleCollection  #Create AZFW

#New ways: New-AzFirewall -VirtualNetwork $vnet.   ;  New-AzFirewall -PublicIpAddress @($publicip1, $publicip2)

$AzfwRoute = New-AzRouteConfig -Name ($Name+$Env+'FwRoute') -AddressPrefix 0.0.0.0/0 -NextHopType VirtualAppliance -NextHopIpAddress $Azfw.IpConfigurations[0].PrivateIPAddress
$AzfwRouteTable = New-AzRouteTable @Params -Name ($Name+$Env+'FwRouteTable')  -Route $AzfwRoute

#associate to Servers Subnet
$vnet.Subnets[2].RouteTable = $AzfwRouteTable
Set-AzVirtualNetwork -VirtualNetwork $vnet
#endregion

#region v2: policy-based firewall creation for vNet not Virtual hub
$FP= Get-AzFirewallPolicy -ResourceGroupName NvStateTstRG -Name NvStateTstFwP
$Azfw = New-AzFirewall @Params -Name ($Name+$Env+'Fw') -SkuName AZFW_VNet -SkuTier Standard -VirtualNetworkName $vnet.Name -PublicIpName $FwPIP.Name -FirewallPolicyId $FP.Id

$AzfwRoute = New-AzRouteConfig -Name ($Name+$Env+'FwRoute') -AddressPrefix 0.0.0.0/0 -NextHopType VirtualAppliance -NextHopIpAddress $Azfw.IpConfigurations[0].PrivateIPAddress #This is the default address prefix for internet traffic
$AzfwRouteTable = New-AzRouteTable @Params -Name ($Name+$Env+'FwRouteTable')  -Route $AzfwRoute

#associate to Servers Subnet
$vnet.Subnets[2].RouteTable = $AzfwRouteTable
Set-AzVirtualNetwork -VirtualNetwork $vnet

#endregion


#endregion


#region v3: Creating the Firewall policy object from scratch
New-AzResourceGroup -Name FWtest -Location 'North Central US'
$subnet= New-AzVirtualNetworkSubnetConfig -Name AzureFirewallSubnet -AddressPrefix 192.168.0.0/26
New-AzVirtualNetwork -ResourceGroupName FWtest -Location 'North Central US' -AddressPrefix 192.168.0.0/24 -Name FWtestvNet -Subnet $subnet -Verbose  #vNet deployment

$FwPol= New-AzFirewallPolicy -Location 'North Central US' -ResourceGroupName FWtest -Name FWtestPolicy -SkuTier Premium -ThreatIntelMode Alert -Verbose  #Firewall deployment

#Application rules. Advised to be used mostly.
$AR1= New-AzFirewallPolicyApplicationRule -Name AR1 -SourceAddress * -Protocol "http:80","https:443" -TargetFqdn '*.microsoft.com', '*.google.com' -Description 'Allow traffic to Microsoft'
$ARC1= New-AzFirewallPolicyFilterRuleCollection -Name ApplicationRuleCollection1 -Priority 400 -Rule $AR1 -ActionType "Allow"
New-AzFirewallPolicyRuleCollectionGroup -Name DefaultApplicationRuleCollectionGroup -Priority 200 -RuleCollection $ARC1 -FirewallPolicyObject $FwPol

#Get-AzFirewallPolicyRuleCollectionGroup -ResourceGroupName FWtest -AzureFirewallPolicyName FWtestPolicy -Name DefaultApplicationRuleCollectionGroup


$testFwPIP = New-AzPublicIpAddress -Location NorthCentralUS -ResourceGroupName FWtest -Name testFwPIP -AllocationMethod Static -Sku Standard 
$testfw = New-AzFirewall -Location NorthCentralUS -ResourceGroupName FWtest -Name testfw -SkuName AZFW_VNet -SkuTier Premium -VirtualNetworkName FWtestvNet -PublicIpName $testFwPIP.Name -FirewallPolicyId $FwPol.Id  #Premium policy can only be used by a premium firewall

#DNAT rules.
$RDPDNATrule= New-AzFirewallPolicyNatRule -Name RDPDNATrule -Protocol TCP -SourceAddress 75.6.182.65 -DestinationAddress $testFwPIP.IpAddress -DestinationPort 3389 -TranslatedAddress 192.168.0.68 -TranslatedPort 3389  #Replace TranslatedAddresswith VM's pricate IP
$NatRuleCollection1= New-AzFirewallPolicyNatRuleCollection -Name NatRuleCollection1 -Priority 200 -Rule $RDPDNATrule -ActionType Dnat -Verbose

New-AzFirewallPolicyRuleCollectionGroup -Name DefaultDnatRuleCollectionGroup  -Priority 300 -RuleCollection $NatRuleCollection1 -FirewallPolicyObject $FwPol -Verbose #PolicyRuleCollectionGroup's priorities need to be unique.

#Get-AzFirewallPolicyRuleCollectionGroup -ResourceGroupName FWtest -AzureFirewallPolicyName FWtestPolicy -Name DefaultDnatRuleCollectionGroup


#endregion



New-AzFirewallPolicyApplicationRule -Name AR1 -SourceAddress "192.168.0.0/16" -Protocol "http:80","https:443" -TargetFqdn "*.ro", "*.com"
New-AzFirewallPolicyFilterRuleCollection -Name FR1 -Priority 400 -Rule $appRule1 ,$appRule2 -ActionType "Allow"
New-AzFirewallPolicyRuleCollectionGroup -Name rg1 -ResourceGroupName TestRg -Priority 200 -RuleCollection $filterRule1 -FirewallPolicyObject $fp


$threatIntelWhitelist = New-AzFirewallPolicyThreatIntelWhitelist -IpAddress 23.46.72.91,192.79.236.79 -FQDN microsoft.com
New-AzFirewallPolicy -Name fp1 -ResourceGroupName TestRg -ThreatIntelWhitelist $threatIntelWhitelist



Get-AzFirewallPolicyRuleCollectionGroup -ResourceGroupName NvStateTstRG -AzureFirewallPolicyName NvStateTstFwP -Name DefaultNetworkRuleCollectionGroup
Get-AzFirewallPolicyRuleCollectionGroup -ResourceGroupName NvStateTstRG -AzureFirewallPolicyName NvStateTstFwP -Name DefaultApplicationRuleCollectionGroup
(Get-AzFirewallPolicyRuleCollectionGroup -ResourceGroupName NvStateTstRG -AzureFirewallPolicyName NvStateTstFwP -Name DefaultApplicationRuleCollectionGroup).Properties.RuleCollection





#region Delete Azure Firewall
$firewall=Get-AzureRmFirewall -ResourceGroupName NLGSUSUATMITVNETRG -Name NLGSUSMITAF
$firewall.Deallocate()
Remove-AzureRmFirewall -ResourceGroupName NLGSUSUATMITVNETRG -Name NLGSUSMITAF -Verbose
#endregion
