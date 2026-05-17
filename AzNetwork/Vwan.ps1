Set-AzContext '<Sub>'


Get-AzVirtualWan |select -ExcludeProperty Tag,TagsTable,ResourceGuid,Etag                       
<#
ProvisioningState          : Succeeded
AllowVnetToVnetTraffic     : True
AllowBranchToBranchTraffic : True
VirtualWANType             : Standard
ResourceGroupName          : '<rg-vwan>'
Location                   : centralus
Type                       : Microsoft.Network/virtualWans
Name                       : '<vwan>'
Id                         : /subscriptions/<Sub>/resourceGroups/<rg-vwan>/providers/Microsoft.Network/virtualWans/'<vwan>'
#>

#region  Virtual Hub

Get-AzVirtualHub -ResourceGroupName '<rg-vwan>'  #This shows same output as Get-AzVirtualHub
Get-AzVirtualHub -ResourceGroupName '<rg-vwan>'|select -First 1|FL *
(Get-AzVirtualHub -ResourceGroupName '<rg-vwan>'|select -First 1).VirtualWan.Id



$VHub = Get-AzVirtualHub -ResourceGroupName '<rg-vwan>' | Select-Object -Skip 1 -First 1

$VNConnections = Get-AzVirtualHubVnetConnection -ResourceGroupName '<rg-vwan>' -ParentResourceName $VHub.Name
$VNConnections  #Count 173| June25
$VNConnections | Select-Object -First 3 -Property Name, ProvisioningState, EnableInternetSecurity, @{n='RouteTableName';e={($_.RoutingConfiguration.AssociatedRouteTable.Id -split '/')[-1]}} 
<#Name               ProvisioningState EnableInternetSecurity RouteTableName
----               ----------------- ---------------------- --------------
'<vnet-01>'         Succeeded                          False defaultRouteTable
'<vnet-02>'         Succeeded                           True defaultRouteTable
'<vnet-03>'         Succeeded                           True defaultRouteTable
#>
#endregion

#region
$RouteTable = Get-AzVHubRouteTable -ResourceGroupName '<rg-vwan>' -HubName $VHub.Name
$RouteTable[0]
$RouteTable[0]|fl

($RouteTable[0].AssociatedConnections).count  #178
($RouteTable[0].PropagatingConnections).count #178
#endregion


#rgion Azure VPN Gateway
#$GW = Get-AzVpnGateway -ResourceGroupName '<rg-vwan>' -Name '<GUID>-<gw name>'
$GW = Get-AzVpnGateway -ResourceGroupName '<rg-vwan>'| Where-Object { $_.VirtualHub.Id -match '<vhub name>' } 
$GW.IpConfigurations
<#Shows the public and private ips of the hub gateway
Id        PublicIpAddress PrivateIpAddress
--        --------------- ----------------
Instance0 <PublicIP0>   <PrivateIP0>
Instance1 <PublicIP1>   <PrivateIP0>
#>
$GW.BgpSettings                                                                                                  
<#Asn BgpPeeringAddress PeerWeight BgpPeeringAddresses
  --- ----------------- ---------- -------------------
65515                            0 {, }
#>

$GW.Connections  #lists vpn sites connected to this gateway
$GW.Connections[1]|fl #shows the second VPN site on the gateway
#endregion



#region VPN site
#$vpnSites = Get-AzVpnSite | Where-Object { $_.VirtualWan.Id -eq $VHub.VirtualWan.Id }
#$vpnSites
#VPN sites are registered at the  VWan level even if the gateways are different. the relationship with the hub is established thru the Gateway connection.
#$VpnSite = Get-AzVpnSite
$GW.Connections[1].RemoteVpnSite.Id
#/subscriptions/<Sub>/resourceGroups/<rg-vwan>/providers/Microsoft.Network/vpnSites/<gw name>

#Querying the site using the Gateway connection's property
Get-AzVpnSite -Name $GW.Connections[1].RemoteVpnSite.Id.Split('/')[-1]

#Gets the VPN sites on a specific Virtual Hub by name
(Get-AzVpnGateway | ? { $_.VirtualHub.Id -match $VHub.Name }).Connections | % { Get-AzVpnSite -Name ($_.RemoteVpnSite.Id.Split('/')[-1]) }
(Get-AzVpnGateway | ? { $_.VirtualHub.Id -match '<vhub name>'}).Connections | % { Get-AzVpnSite -Name ($_.RemoteVpnSite.Id.Split('/')[-1]) }


$Site = (Get-AzVpnSite)[1]
$Site.AddressSpace
<#
AddressPrefixes   IpamPoolPrefixAllocations AddressPrefixesText
---------------   ------------------------- -------------------
{<CIDR>/32} {}                        […
#>
$Site.BgpSettings  #Null
$Site.DeviceProperties
<#
DeviceModel DeviceVendor LinkSpeedInMbps
----------- ------------ ---------------
            <VendorName>        0
#>

Get-AzVpnSiteLinkConnectionIkeSa -ResourceGroupName '<rg-vwan>' -VpnGatewayName '<GUID>-<gw name>' -VpnConnectionName 'Connection-<gw name>' -Name '<Name>RemoteNprdVnetSite1link1'

$GW = (Get-AzVpnGateway | ? { $_.Connections.RemoteVpnSite.Id -match "/$($Site.Name)$" })   #Querying the Gateway of a VPN site by name
Get-AzVpnSiteLinkConnectionIkeSa -ResourceGroupName $Site.ResourceGroupName -VpnGatewayName $GW.Name -VpnConnectionName ('Connection-'+$Site.Name) -Name $Site.VpnSiteLinks.Name
<#localEndpoint            : <PublicIpOfInitiator>
remoteEndpoint             : <RemotePublicIp>
initiatorCookie            : 7240635664121786952
responderCookie            : 17348192600152882099
localUdpEncapsulationPort  : 0
remoteUdpEncapsulationPort : 0
encryption                 : AES256
integrity                  : SHA384
dhGroup                    : DHGroup14
lifeTimeSeconds            : 28810
isSaInitiator              : False
elapsedTimeInseconds       : 1531
quickModeSa                : {}
#>

#endregion




#User VPN configurations| None set.
#Get-AzVirtualWanVpnServerConfiguration -Name $virtualWanName -ResourceGroupName $resourceGroupName


# Step 1: Retrieve the connection monitor configurations in the specified virtual WAN hub
#Get-AzNetworkWatcherConnectionMonitor -Location "yourLocation" -NetworkWatcherName "yourNetworkWatcherName" -ResourceGroupName "yourResourceGroupName" 




Get-AzVirtualHubVnetConnection -ResourceGroupName $Site.ResourceGroupName -VirtualHubName $VHub.Name | Where-Object { $_.RemoteVirtualNetwork.Id -match '<VnetName>' }

Where-Object { $_.RemoteVirtualNetwork.Id -match "/$($Site.Name)$" }



#region get propagation state for a VPN site. 
#But this just means that the Default route table on the hub is being propagated to the VPN site.
#This does not mean all the vnet connections of the hub are being propagated to the other side of the VPN connection
$Site = Get-AzVpnSite -Name '<gw name>'
$DefaultRT = Get-AzVHubRouteTable -ResourceGroupName '<rg-vwan>' -HubName $VHub.Name -Name defaultRouteTable

[PSCustomObject]@{ Site = $Site.Name; RouteTableName = $DefaultRT.Name
  PropagationState = [bool]($RT.PropagatingConnections -match "$($Site.Name)") 
}
<#Site RouteTableName    PropagationState
---- --------------    ----------------
     defaultRouteTable             True
#>
#endregion




#region testing hops to onprem DC

Resolve-DnsName '<Domain>.local'
<#
Name                                           Type   TTL   Section    IPAddress
----                                           ----   ---   -------    ---------
<Domain>.local                                       A      600   Answer     <Dc1PrivateIP>
<Domain>.local                                       A      600   Answer     <Dc2PrivateIP>
<Domain>.local                                       A      600   Answer     <D3PrivateIP>
<Domain>.local                                       A      600   Answer     <Dc4PrivateIP>
<Domain>.local                                       A      600   Answer     <Dc5PrivateIP>
<Domain>.local                                       A      600   Answer     <Dc6PrivateIP>
#>



Test-NetConnection '<Dc1PrivateIP>' -InformationLevel Detailed -TraceRoute
<#
ComputerName           : <Dc1PrivateIP>
RemoteAddress          : <Dc1PrivateIP>
NameResolutionResults  : <Dc1PrivateIP>
                         radc2.<Domain>.local
InterfaceAlias         : Ethernet
SourceAddress          : <SourceAzVmPrivateIp>
NetRoute (NextHop)     : <AzVnetVirtualRouterPrivateIp>
PingSucceeded          : True
PingReplyDetails (RTT) : 6 ms
TraceRoute             : <AzFirewall SNAT PrivateIP>
                         <AzPrivateIP1>
                         <AzFirewall SNAT PrivateIP1>
                         <OnpremRouterPrivateIP>
                         <OnpremPrivateIP1>
                         <OnpremPrivateIP2>
                         <Dc1PrivateIP>     radc2.<Domain>.local
#>



pathping '<Dc1PrivateIP>'   

<#Tracing route to radc2.<Domain>.local [<Dc1PrivateIP>]
over a maximum of 30 hops:
  0  <SourceAzVmName>.<Domain>.local [<SourceAzVmPrivateIp>]
  1  <AzFirewall SNAT PrivateIP>
  2  <AzPrivateIP1>
  3  <AzFirewall SNAT PrivateIP1>
  4  <OnpremRouterPrivateIP>
  5  <OnpremPrivateIP1>
  6  <OnpremPrivateIP2>
  7  radc2.<Domain>.local [<Dc1PrivateIP>]

Computing statistics for 175 seconds...
            Source to Here   This Node/Link
Hop  RTT    Lost/Sent = Pct  Lost/Sent = Pct  Address
  0                                           <SourceAzVmName>.<Domain>.local [<SourceAzVmPrivateIp>]
                                0/ 100 =  0%   |
  1  ---     100/ 100 =100%   100/ 100 =100%  <AzFirewall SNAT PrivateIP>
                                0/ 100 =  0%   |
  2    7ms     0/ 100 =  0%     0/ 100 =  0%  <AzPrivateIP1>
                                0/ 100 =  0%   |
  3  ---     100/ 100 =100%   100/ 100 =100%  <AzFirewall SNAT PrivateIP1>
                                0/ 100 =  0%   |
  4  ---     100/ 100 =100%   100/ 100 =100%  <OnpremRouterPrivateIP>
                                0/ 100 =  0%   |
  5  ---     100/ 100 =100%   100/ 100 =100%  <OnpremPrivateIP1>
                                0/ 100 =  0%   |
  6    9ms     0/ 100 =  0%     0/ 100 =  0%  <OnpremPrivateIP2>
                                0/ 100 =  0%   |
  7    6ms     0/ 100 =  0%     0/ 100 =  0%  radc2.<Domain>.local [<Dc1PrivateIP>]

Trace complete.
#>

#endregion