$Name,$Location = 'AzPETest','NorthCentralUS'
$RG             = New-AzResourceGroup -Location $Location -Name ($Name+'RG') 
$Params         = @{ResourceGroupName  = $RG.ResourceGroupName; Location = $Location; Verbose=$true }

#v1
$Subnets        = @{"myBackendSubnet"="10.0.0.0/24";"AzureBastionSubnet"="10.0.1.0/24"}
$Subnets.Keys | % {New-Variable -Name "$PSItem" -Value $(New-AzVirtualNetworkSubnetConfig -Name $_ -AddressPrefix $Subnets.Item($_) ) -Force} #-Force needed since A variable with name 'myBackendSubnet' already exists. Although it's empty
$vnet           = New-AzVirtualNetwork @Params -Name ($Name+'vNet') -AddressPrefix 10.0.0.0/16 -Subnet $myBackendSubnet,$AzureBastionSubnet   # Create the virtual network

#v2
$SubnetArray=@()
(@{"myBackendSubnet"="10.0.0.0/24";"AzureBastionSubnet"="10.0.1.0/24"}).Keys | % { $SubnetArray+= New-AzVirtualNetworkSubnetConfig -Name $_ -AddressPrefix $Subnets.Item($_)    }

@{"myBackendSubnet"="10.0.0.0/24"} | ForEach-Object { $SubnetArray+= New-AzVirtualNetworkSubnetConfig -Name $_.Keys -AddressPrefix $_.Values    }   #Works

New-AzVirtualNetwork @Params -Name ($Name+'vNet') -AddressPrefix 10.0.0.0/16 -Subnet $SubnetArray

#region v3
$MOTSid,$AppName,$Env,$Location = '30050','SPrehoming','PoC','EastUS2'
$RG      = New-AzResourceGroup -Location $Location -Name "$MOTSid-$Location-$AppName-rg"
$Params  = @{ResourceGroupName  = $RG.ResourceGroupName; Location = $Location; Verbose=$true }
$SubnetArray = @()
(@{"$Location-$MOTSid-$Env-vNet-SQ-snet-01"="192.168.0.0/29";"$Location-$MOTSid-$Env-vNet-Ap-snet-01"="192.168.0.8/29";"$Location-$MOTSid-$Env-vNet-FS-snet-01"="192.168.0.16/29"}).GetEnumerator()| 
        ForEach-Object { $SubnetArray+= New-AzVirtualNetworkSubnetConfig -Name $Psitem.Key -AddressPrefix $Psitem.Value -NetworkSecurityGroup $NSG} #NSG to be created separately

$Vnet    = New-AzVirtualNetwork @Params -Name "$Location-$MOTSid-$Env-vnet-$AppName" -AddressPrefix 192.168.0.0/27 -Subnet $SubnetArray
#endregion

#region: v4
$SubnetConfigs = @{DataTier = '192.168.0.0/29'; AppTier = '192.168.0.8/29'; WebTier = '192.168.0.16/29'}.GetEnumerator() | 
                        ForEach-Object {New-AzVirtualNetworkSubnetConfig -Name $_.Key -AddressPrefix $_.Value -NetworkSecurityGroup $NSG}
New-AzVirtualNetwork -Name ('tiered' + (Get-Suffix)) @AzParams -AddressPrefix 192.168.0.0/27 -Subnet $SubnetConfigs  
#endregion



#region  Check resource usage against limits|   https://docs.microsoft.com/en-us/azure/networking/check-usage-against-limits
Get-AzNetworkUsage -Location eastus | Where-Object {$_.CurrentValue -gt 0} | Format-Table ResourceType, CurrentValue, Limit

<# Output
ResourceType            CurrentValue Limit
------------            ------------ -----
Virtual Networks                   1    50
Network Security Groups            2   100
Public IP Addresses                1    60
Network Interfaces                 1 24000
Network Watchers                   1     1
#>
#endregion


#Reset a VPN Gateway
$gw = Get-AzureRmVirtualNetworkGateway -ResourceGroupName network -Name Virtual_Gateway
Reset-AzureRmVirtualNetworkGateway -VirtualNetworkGateway $gw -verbose



#convert existing NIC IP address configuration to static
$Nic = Get-AzureRmNetworkInterface -ResourceGroupName NLGSUSDVMRASRG2 -Name NLGDVMRASTABVM2NIC01
$Nic.IpConfigurations[0].PrivateIpAllocationMethod = "Static"
$Nic|Set-AzureRmNetworkInterface



#Check if a given VM SKU supports accelerated networking
Get-AzComputeResourceSku | where {$_.Locations -icontains "northcentralus" -and $_.ResourceType.Contains("virtualMachines") -and $_.Capabilities.AcceleratedNetworkingEnabled -eq $True } #syntax needs to be rectified


#Enable accelerated networking on existing VM
$nic = Get-AzNetworkInterface -ResourceGroupName NLGSUSDVMoveItRG1 -Name nlgdvmoveitvm1_nic
$nic.EnableAcceleratedNetworking = $true
$nic | Set-AzNetworkInterface -Verbose




az network nic update --name <nic_name> --resource-group <resource_group_name> --accelerated-networking false  #Azcli to disable accelerated networking. Powershell login wasn't working

$NIC.EnableAcceleratedNetworking = $false; $NIC | Set-AzNetworkInterface  #works now



#All Azure vNic settings
$Nic = Get-AzureRmNetworkInterface -ResourceGroupName "ResourceGroup1" -Name "NetworkInterface1"
$Nic.IpConfigurations[0].PrivateIpAddress = "10.0.1.20"
$Nic.IpConfigurations[0].PrivateIpAllocationMethod = "Static"
$Nic.Tag = @{Name = "Name"; Value = "Value"}
$nic.EnableIPForwarding = 1
$nic.DnsSettings.DnsServers.Add("192.168.1.100")
Set-AzureRmNetworkInterface -NetworkInterface $Nic -Verbose

$nic = New-AzureRmNetworkInterface -Name TestNIC -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -PrivateIpAddress 192.168.1.101









((Get-AzureRmVM -ResourceGroupName NLGSUSUTCDCPVMRG01 -Name NLGUTCDCPAIVM01).NetworkProfile).NetworkInterfaces

((Get-AzureRmNetworkInterface -ResourceGroupName NLGSUSUTCDCPVMRG01 -Name NLGUTCDCPCDBVM1NIC01).IpConfigurations).PrivateIpAddress   #IP address of a virtual machine's NIC




#Name IP and allocation  method of vNIC's
Get-AzureRmNetworkInterface -ResourceGroupName NLGSUSUTMRASRG2|select -Property name, @{n='IpAllocationMethod';e={$_.IpConfigurations.PrivateIpAllocationMethod}},@{n='PrivateIpAddress';e={$_.IpConfigurations.PrivateIpAddress}}




#GEt Vnet DNS server
(Get-AzureRmVirtualNetwork -ResourceGroupName NLGNUSUTMRASRG-asrTest -Name NLGNUSUATDRMRASVN01-asrTest).DhcpOptionsText


#region Create Hub Vnet and connect to Expressroute
$GWIPName = "NLGNPRDHubVNGWPIP"
$RG = "NLGNPRDHubVNRG"
$Location="southcentralus"
$VNetName="NLGNPRDHubVN"
$GWIPconfName="NLGNPRDHubVNGWCONF"
$GWName = "NLGNPRDHubVNGW"



$Vnet = New-AzureRmVirtualNetwork -ResourceGroupName $RG -Name $VNetName -AddressPrefix 10.191.241.0/24 -Location $Location -Verbose
Add-AzureRmVirtualNetworkSubnetConfig -Name GatewaySubnet -VirtualNetwork $vnet -AddressPrefix 10.191.241.0/27 -Verbose
$vnet.DhcpOptions.DnsServers = "10.191.0.4" 
$vnet.DhcpOptions.DnsServers +="10.191.3.4" 
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet -Verbose









$gwpip    = New-AzureRmPublicIpAddress -Name $GWIPName -ResourceGroupName $RG -Location $Location -AllocationMethod Dynamic -Verbose
#$vnet     = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $RG -Verbose
$subnet   = Get-AzureRmVirtualNetworkSubnetConfig -Name GatewaySubnet -VirtualNetwork $vnet -Verbose
$gwipconf = New-AzureRmVirtualNetworkGatewayIpConfig -Name $GWIPconfName -Subnet $subnet -PublicIpAddress $gwpip -Verbose

$gw= New-AzureRmVirtualNetworkGateway -Name $GWName -ResourceGroupName $RG -Location $Location -IpConfigurations $gwipconf -GatewayType ExpressRoute -VpnType RouteBased -GatewaySku Standard -Verbose





$circuit = Get-AzureRmExpressRouteCircuit -Name NLGEXPRPRODCIR -ResourceGroupName NLGEXPRRG01

#$gw = Get-AzureRmVirtualNetworkGateway -Name NLGNPRDHubVNGW -ResourceGroupName NLGNPRDHubVNRG

$connection = 


New-AzureRmVirtualNetworkGatewayConnection -Name NLGNPRDHubVNGWC -ResourceGroupName NLGNPRDHubVNRG -Location southcentralus -VirtualNetworkGateway1 $gw -PeerId $circuit.Id -ConnectionType ExpressRoute -Verbose 
#endregion 

#region Hub and Spoke Peering
Select-AzSubscription -SubscriptionName NLG-MOVEIT -Verbose
#SpokePeering
Add-AzVirtualNetworkPeering -Name NLGNPRDHubVNP -VirtualNetwork $(Get-AzVirtualNetwork -Name NLGSUSNPRDMITVNET -ResourceGroupName NLGSUSNPRDMITVNETRG) -AllowForwardedTraffic -UseRemoteGateways -RemoteVirtualNetworkId /subscriptions/18414daa-8753-4f63-99d1-a4b3c285e134/resourceGroups/NLGNPRDHubVNRG/providers/Microsoft.Network/virtualNetworks/NLGNPRDHubVN -Verbose    

Select-AzSubscription -SubscriptionName NLG-EXPR-PROD -Verbose
#HubPeering
Add-AzVirtualNetworkPeering -Name NLGSUSNPRDMITVNETP -VirtualNetwork $(Get-AzVirtualNetwork -Name NLGNPRDHubVN -ResourceGroupName NLGNPRDHubVNRG) -AllowForwardedTraffic -AllowGatewayTransit -RemoteVirtualNetworkId /subscriptions/7bc01d86-c817-4425-a2cd-7764a1629f4c/resourceGroups/NLGSUSNPRDMITVNETRG/providers/Microsoft.Network/virtualNetworks/NLGSUSNPRDMITVNET -Verbose


Get-AzVirtualNetworkPeering -ResourceGroupName NLGNPRDHubVNRG -VirtualNetworkName NLGNPRDHubVN | Select Name,PeeringState
#endregion




#region Hub and spoke troubleshooting during DR failover failure

#get peer ip for gateway
Get-AzureRmVirtualNetworkGatewayBgpPeerStatus -ResourceGroupName NLGPRDHubVNRG -VirtualNetworkGatewayName NLGPRDHubVNGW -Verbose|select -Property *

<#Output
LocalAddress      : 10.191.240.12   #IP of the instance of the gateway. it is active-active in the backend. sometimes it can show up with the secondary IP
Neighbor          : 10.191.240.4    #this is the IP of the Microsoft router that this gateway is peered with.
Asn               : 12076
State             : Connected
ConnectedDuration : 4.04:22:02.1129712   #connected duration for this gateway
RoutesReceived    : 138
MessagesSent      : 6897
MessagesReceived  : 6714

LocalAddress      : 10.191.240.12
Neighbor          : 10.191.240.5
Asn               : 12076
State             : Connected
ConnectedDuration : 4.04:22:02.0678120
RoutesReceived    : 138
MessagesSent      : 6892
MessagesReceived  : 6714
#>


#List the address spaces the Prod hub is advertizing
Get-AzureRmVirtualNetworkGatewayAdvertisedRoute -VirtualNetworkGatewayName NLGPRDHubVNGW -ResourceGroupName NLGPRDHubVNRG -Peer 10.191.240.4 -Verbose




#List the address spaces the Dr hub is advertizing
Get-AzureRmVirtualNetworkGatewayAdvertisedRoute -VirtualNetworkGatewayName NLGDRHubVNGW -ResourceGroupName NLGDRHubVNRG -Peer 10.191.242.4 -Verbose



#checks route table for an express route circuit
Get-AzureRmExpressRouteCircuitRouteTable -ResourceGroupName NLGEXPRRG01 -ExpressRouteCircuitName NLGEXPRPRODCIR -PeeringType AzurePrivatePeering -DevicePath Primary


Get-AzureRmExpressRouteCircuitRouteTable -ResourceGroupName NLGEXPRRG01 -ExpressRouteCircuitName NLGEXPRPRODCIR -PeeringType AzurePrivatePeering -DevicePath Primary|? Network -EQ '10.191.10.0/24'



Get-AzureRmExpressRouteCircuitRouteTableSummary -ResourceGroupName NLGEXPRRG01 -ExpressRouteCircuitName NLGEXPRPRODCIR -PeeringType AzurePrivatePeering -DevicePath Primary -Verbose


Get-AzureRmExpressRouteCircuitARPTable -ResourceGroupName NLGEXPRRG01 -ExpressRouteCircuitName NLGEXPRPRODCIR -PeeringType AzurePrivatePeering -DevicePath Primary    #get onprem device ip
get uptime for a specific advertisement.



#One of these sets resolved the issue will have to retry.
Get-AzureRmVirtualNetwork -ResourceGroupName NLGPRDHubVNRG -Name NLGPRDHubVN|Set-AzureRmVirtualNetwork -Verbose
Get-AzureRmVirtualNetworkGatewayConnection -ResourceGroupName NLGPRDHubVNRG -Name NLGPRDHubVNGWC -Verbose|Set-AzureRmVirtualNetworkGatewayConnection -Verbose


#endregion





#region Peer existing spoke vnet with existing Vwan hub
Select-AzSubscription '<>'
$SpokeVnet = Get-AzVirtualNetwork -ResourceGroupName 'rg-avd-d-c-02' -Name 'vnet-AVDEnt-d-01'


Select-AzSubscription '<>'
# Get Virtual WAN and Virtual Hub
$Vwan = Get-AzVirtualWan -ResourceGroupName 'rg-vwan-p-c-01' -Name 'vwan-p-c-01'
$Vhub = Get-AzVirtualHub -ResourceGroupName 'rg-vwan-p-c-01' -Name 'vhub-p-c-01'

#$rt1 = Get-AzVHubRouteTable -ResourceGroupName 'rg-vwan-p-c-01' -VirtualHubName 'vhub-p-c-01' -Name DefaultRouteTable
#$routingconfig = New-AzRoutingConfiguration -AssociatedRouteTable $rt1.Id -Label @("default") -Id @($rt1.Id)|fl  #-StaticRoute @($route1)

#$connection = Get-AzVirtualHubVnetConnection -ResourceGroupName 'rg-vwan-p-c-01' -ParentResourceName vhub-p-c-01 -Name 'vnet-dvsonline-d-c-01'



# Create VNet connection to Virtual Hub
New-AzVirtualHubVnetConnection -ResourceGroupName 'rg-vwan-p-c-01' -VirtualHubName 'vhub-p-c-01' -Name 'vnet-AVDEnt-d-01' -RemoteVirtualNetworkId $SpokeVnet.Id  -Verbose

    #-RoutingConfiguration $routingconfig   #Didn't work. Error: RoutingConfiguration'. Specified method is not supported.
    #-EnableInternetSecurity $false  #Didn't try

# Verify the connection
$vhub = Get-AzVirtualHub -ResourceGroupName $resourceGroupName -Name $vhubName
$vhub.VirtualNetworkConnections|? Name -eq 'vnet-AVDEnt-d-01'|FL

#endregion


#check Azure latency. Module  AzSpeedTest
Test-AzRegionLatency -Region centralindia -Verbose

#To delete custom routes
Set-AzVirtualNetworkGateway -VirtualNetworkGateway $gw -CustomRoute @0



#Download profile on the client
$profile=Get-AzVpnClientConfiguration -ResourceGroupName RG-Ztech-Dev-001 -Name GW-Ztech-Dev-001 -Verbose 
$profile.VPNProfileSASUrl




#region NetworkWatcher
Set-AzVMExtension -ResourceGroupName VMRG -Location northcentralus -VMName VM -Name networkWatcherAgent -Publisher Microsoft.Azure.NetworkWatcher -Type NetworkWatcherAgentWindows -TypeHandlerVersion 1.4 -Verbose #Worked


$networkWatcher =Get-AzNetworkWatcher -Location northcentralus  #The location is case sensitive

$target = '/subscriptions/<>/resourceGroups/VMRG/providers/Microsoft.Compute/virtualMachines/VM'
$storageId = '/subscriptions/<>/resourceGroups/StorageRG/providers/Microsoft.Storage/storageAccounts/storagenus'
$storagePath = 'https://storagenus.blob.core.windows.net/testblob'


Test-AzNetworkWatcherConnectivity -NetworkWatcherName NetworkWatcher_northcentralus -ResourceGroupName NetworkWatcherRG -SourceId $target -DestinationAddress "bing.com" -DestinationPort 443 -Verbose    #Worked
<#
ConnectionStatus AvgLatencyInMs MinLatencyInMs MaxLatencyInMs ProbesSent ProbesFailed
---------------- -------------- -------------- -------------- ---------- ------------
Reachable        1              1              6              66         0
#>

$test.Hops|ft
$test.HopsText

Test-AzNetworkWatcherConnectivity -NetworkWatcherName NetworkWatcher_northcentralus -ResourceGroupName NetworkWatcherRG -SourceId $target -DestinationAddress $storagePath -DestinationPort 443 -Verbose  #Worked

#Works only with VM id in destination. Doesn'twork with LB id or NIC id or storage account id
Test-AzNetworkWatcherConnectivity -NetworkWatcherName NetworkWatcher_northcentralus -ResourceGroupName NetworkWatcherRG -SourceId $target -DestinationId $VM.Id -DestinationPort 443 -Verbose  

#Works for virtual network gateway to storage account connectivity check.
Start-AzNetworkWatcherResourceTroubleshooting -NetworkWatcher $networkWatcher -TargetResourceId $target -StorageId $storageId -StoragePath $storagePath
Get-AzNetworkWatcherTroubleshootingResult -NetworkWatcher $NW -TargetResourceId $target


#CLI for latency report. Couldn't get to work
Get-AzNetworkWatcherReachabilityReport -NetworkWatcher $networkWatcher -Location "West US" -Country "United States" -StartTime "2022-01-15" -EndTime "2022-01-15"

#Worked. blank output
Get-AzNetworkWatcherSecurityGroupView -NetworkWatcher $networkWatcher -TargetVirtualMachineId $target -Verbose

<#
NetworkInterfaces : []
#>

#Worked. But output not useful. Need to try '-TargetNetworkInterfaceId'
$VM = Get-AzVM -ResourceGroupName VMRG -Name VM
$Nics = Get-AzNetworkInterface | Where-Object {$_.Id -eq $vm.NetworkProfile.NetworkInterfaces.Id.ForEach({$_})}
Get-AzNetworkWatcherNextHop -NetworkWatcher $networkWatcher -TargetVirtualMachineId $VM.Id -SourceIPAddress $nics[0].IpConfigurations[0].PrivateIpAddress  -DestinationIPAddress 204.79.197.200  #Bing's public IP



#Packet capture steps: https://docs.microsoft.com/en-us/azure/network-watcher/network-watcher-packet-capture-manage-powershell


#endregion



#If you want to create a zone-redundant Public IP address, please specify all the zones in the region. For example, Zone = ['1', '2', '3'].
New-AzPublicIpAddress @Params -Name ($Name+'PIP') -Sku Standard -AllocationMethod Static -Zone $Null
<#
warning
Old Way : Sku = Standard means the Standard Public IP is zone-redundant.
    New Way : Sku = Standard and Zone = {} means the Standard Public IP has no zones. 
#>




(Get-AzNetworkServiceTag -Location australiacentral).Values|? Name -Like APIManagement  #Query service tags
#One can do custom advertisement of service tags to Azure VPN. Example in BitBucket DevConsumption


#region Reset a NIC
$subnet = Get-AzVirtualNetworkSubnetConfig -Name repair-W10VM_Subnet -VirtualNetwork (Get-AzVirtualNetwork -Name repair-W10VM_VNET)
$pip    = Get-AzPublicIpAddress -Name W11repair-ip
$nic    = Get-AzNetworkInterface -Name w11repair670

$nic | Set-AzNetworkInterfaceIpConfig -Name ipconfig1 -PrivateIpAddress 10.0.0.5 -Subnet $subnet -PublicIpAddress $pip -Primary -Verbose
$nic | Set-AzNetworkInterface -Verbose


#CLI | Resolved Error: Remote Desktop Connection : A certification authority could not be contacted for authentication. If you are using a Remote Desktop Gateway with a smart card, try connecting to the remote computer using a password. For assistance, contact your system administrator or technical support.
az vm repair reset-nic -g W11ARMRG -n W11ARM --subscription <> --yes --verbose
#This command is in preview and under development. Reference and support levels: https://aka.ms/CLI_refstatus

#endregion


#region  get the vnets that are peered along with the number of devices connected to it.
$vnets = Get-AzVirtualNetwork
$results = $vnets | ForEach-Object {
    $addressRange = $_.AddressSpace.AddressPrefixes -join ', '
    $connectedDevicesCount = (Get-AzNetworkInterface | Where-Object { $_.IpConfigurations.Subnet.Id -like "*$($_.Id)/*" }).Count
    [PSCustomObject]@{
        VNetName         = $_.Name
        AddressRange     = $addressRange
        ConnectedDevices = $connectedDevicesCount
        Peering          = $_.VirtualNetworkPeerings
    }
}

$results | Sort-Object Peering | Format-Table -AutoSize
#endregion