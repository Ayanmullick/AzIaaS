#region Express route  hybrid connection remap in 'HybridConnectionFlow.md'
$expressRouteCircuits = Get-AzExpressRouteCircuit
$expressRouteCircuits
$expressRouteCircuits.Sku  
<#Name                 Tier     Family
----                 ----     ------
Standard_MeteredData Standard MeteredData
#>

$expressRouteCircuits.ServiceProviderProperties
<#ServiceProviderName PeeringLocation BandwidthInMbps
------------------- --------------- ---------------
Equinix             Chicago                    1000
#>

$expressRouteCircuits.Peerings|fl


$expressRouteCircuits.Peerings.MicrosoftPeeringConfig
<#AdvertisedPublicPrefixes      : {}
AdvertisedCommunities         : {}
AdvertisedPublicPrefixesState : NotConfigured
CustomerASN                   : 0
LegacyMode                    : 0
RoutingRegistryName           : NONE
AdvertisedPublicPrefixesSText : []
AdvertisedCommunitiesSText    : []
#>


$ERCConfig = Get-AzExpressRouteCircuit|Get-AzExpressRouteCircuitPeeringConfig
$ERCConfig|fl


Get-AzExpressRouteGateway -ResourceGroupName '<rg-vwan>'|fl

#Gets the whole route table. Takes mins to fetch
Get-AzExpressRouteCircuitRouteTable -ResourceGroupName '<rg-vwan>' -ExpressRouteCircuitName '<CircuitName>' -PeeringType 'AzurePrivatePeering' -DevicePath 'Primary'
<#Network            NextHop       LocPrf Weight Path
-------            -------       ------ ------ ----
0.0.0.0/0          172.25.1.15*  100    0      65515 I…
0.0.0.0/0          172.25.1.14   100    0      65515 I…
10.1.90.0/24       192.168.60.3  100    0      64998 ?…
10.1.99.0/30       192.168.60.3  100    0      64998 ?…
10.1.99.24/29      192.168.60.3  100    0      64998 ?…
10.1.99.36/30      192.168.60.3  100    0      64998 ?…
10.1.99.48/30      192.168.60.3  100    0      64998 ?…
10.1.99.72/30      192.168.60.3  100    0      64998 ?…
10.1.99.80/29      192.168.60.3  100    0      64998 ?…
10.1.99.104/29     192.168.60.3  100    0      64998 ?…
10.1.99.112/30     192.168.60.3  100    0      64998 ?
.........
.............
#>

<#BGP neighbors visible from the ExpressRoute circuit’s Microsoft edge routing context for Azure private peering
#>

Get-AzExpressRouteCircuitRouteTableSummary -ResourceGroupName '<rg-vwan>' -ExpressRouteCircuitName '<CircuitName>' -PeeringType 'AzurePrivatePeering' -DevicePath 'Primary'
<#Neighbor      V AsProperty UpDown StatePfxRcd
--------      - ---------- ------ -----------
152.162.50.93 4 65000      52w1d  88               Your customer/provider-side BGP peer for ExpressRoute private peering. This is likely the CE/PE-side IP on the primary ExpressRoute peering link.
172.25.1.14   4 65515      3d     185              Azure internal BGP peer, likely an ExpressRoute gateway / Virtual WAN hub routing instance advertising Azure-side routes into the circuit.
172.25.1.15   4 65515      3d     185              Another Azure internal BGP peer for redundancy/scale, likely the paired gateway/hub routing instance.
192.168.60.3  4 12076      42w2d  993              Microsoft/Azure-side BGP peer within the Microsoft ExpressRoute routing fabric. Microsoft uses AS 12076 for ExpressRoute peerings.
#>



#endregion