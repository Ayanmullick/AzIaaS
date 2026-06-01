#region <NLG> ESB DR Express route connection

Select-AzureRmSubscription -SubscriptionName '<>-OCS' -Verbose
$GWIPName1 = "<>NUSDRAPIVNETPIP"
$RG1 = "<>PDAPIVNETRG01-asr"
$Location1="northcentralus"
$VNetName1="<>PDAPIVN01-asr"
$GWIPconfName1="<>NUSDRAPIVNETGWCONF"
$GWName1 = "<>NUSDRAPIVNETGW"

$gwpip1 = New-AzureRmPublicIpAddress -Name $GWIPName1 -ResourceGroupName $RG1 -Location $Location1 -AllocationMethod Dynamic -Verbose
$vnet1     = Get-AzureRmVirtualNetwork -Name $VNetName1 -ResourceGroupName $RG1 -Verbose
$subnet1   = Get-AzureRmVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet1 -Verbose
$gwipconf1 = New-AzureRmVirtualNetworkGatewayIpConfig -Name $GWIPconfName1 -Subnet $subnet1 -PublicIpAddress $gwpip1 -Verbose

New-AzureRmVirtualNetworkGateway -Name $GWName1 -ResourceGroupName $RG1 -Location $Location1 -IpConfigurations $gwipconf1 -GatewayType ExpressRoute -VpnType RouteBased -GatewaySku Standard -Verbose


#------------------------
# create circuit authorization.
Select-AzureRmSubscription -SubscriptionName '<>-EXPR-PROD' -Verbose
$circuit = Get-AzureRmExpressRouteCircuit -Name "<>EXPRPRODCIR" -ResourceGroupName "<>EXPRRG01" -Verbose
Add-AzureRmExpressRouteCircuitAuthorization -ExpressRouteCircuit $circuit -Name "<>ESBDRAuth1" -Verbose
Set-AzureRmExpressRouteCircuit -ExpressRouteCircuit $circuit -Verbose


$auth1 = Get-AzureRmExpressRouteCircuitAuthorization -ExpressRouteCircuit $circuit -Name "<>ESBDRAuth1"

#link Vnet to express route

Select-AzureRmSubscription -SubscriptionName '<>-Moveit' -Verbose

$id = $circuit.Id  
$gw = Get-AzureRmVirtualNetworkGateway -Name "<>SUSNPRDMITVNETGW" -ResourceGroupName "<>SUSNPRDMITVNETRG" -Verbose
$connection = New-AzureRmVirtualNetworkGatewayConnection -Name "ExprRouteConnection" -ResourceGroupName "<>SUSNPRDMITVNETRG" -Location "southcentralUS" -VirtualNetworkGateway1 $gw -PeerId $id -ConnectionType ExpressRoute -AuthorizationKey $auth1.AuthorizationKey -Verbose

#Variables-- 4






#region DR Failover

Select-AzureRmSubscription -SubscriptionName '<>-OCS' -Verbose
Remove-AzureRmVirtualNetworkGatewayConnection -Name '<>PDAPIVNGWCONN01' -ResourceGroupName '<>PDAPIVNETRG01' -Verbose




Select-AzureRmSubscription -SubscriptionName '<>-EXPR-PROD' -Verbose
$circuit = Get-AzureRmExpressRouteCircuit -Name "<>EXPRPRODCIR" -ResourceGroupName "<>EXPRRG01" -Verbose
$auth1 = Get-AzureRmExpressRouteCircuitAuthorization -ExpressRouteCircuit $circuit -Name "<>ESBDRAuth1"

#link DR Vnet to express route

Select-AzureRmSubscription -SubscriptionName '<>-OCS' -Verbose
$id = $circuit.Id  
$gw = Get-AzureRmVirtualNetworkGateway -Name "<>NUSDRAPIVNETGW" -ResourceGroupName "<>PDAPIVNETRG01-asr" -Verbose
$connection = New-AzureRmVirtualNetworkGatewayConnection -Name "<>DRAPIVNGWCONN01" -ResourceGroupName "<>PDAPIVNETRG01-asr" -Location "northcentralUS" -VirtualNetworkGateway1 $gw -PeerId $id -ConnectionType ExpressRoute -AuthorizationKey $auth1.AuthorizationKey -Verbose
#endregion



#Disconnect DR VNet

Select-AzureRmSubscription -SubscriptionName '<>-OCS' -Verbose
Remove-AzureRmVirtualNetworkGatewayConnection -Name '<>DRAPIVNGWCONN01' -ResourceGroupName '<>PDAPIVNETRG01-asr' -Verbose



#Reconnect the Prod Vnet

Select-AzureRmSubscription -SubscriptionName '<>-EXPR-PROD' -Verbose
$circuit = Get-AzureRmExpressRouteCircuit -Name "<>EXPRPRODCIR" -ResourceGroupName "<>EXPRRG01" -Verbose
$auth1 = Get-AzureRmExpressRouteCircuitAuthorization -ExpressRouteCircuit $circuit -Name "APIPRODAUTHORIZATION01"

Select-AzureRmSubscription -SubscriptionName '<>-OCS' -Verbose
$id = $circuit.Id  
$gw = Get-AzureRmVirtualNetworkGateway -Name "<>PDAPIVNGW01" -ResourceGroupName "<>PDAPIVNETRG01" -Verbose
$connection = New-AzureRmVirtualNetworkGatewayConnection -Name "<>PDAPIVNGWCONN01" -ResourceGroupName "<>PDAPIVNETRG01" -Location "southcentralUS" -VirtualNetworkGateway1 $gw -PeerId $id -ConnectionType ExpressRoute -AuthorizationKey $auth1.AuthorizationKey -Verbose



#Delete the DR failover disks if needed | Since we didn't use Test Failover the cleanup needs to be done manually
Get-AzureRmDisk -ResourceGroupName '<>PDAPIRG01-asr'|? Name -NotLike '*replica*'|Remove-AzureRmDisk -Verbose

#endregion