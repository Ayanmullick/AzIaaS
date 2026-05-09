
#region Add IP CIDR range to existing IP group
(Get-AzIpGroup -Name 'ipgroup-<>').IpAddresses

$IpGroup = Get-AzIpGroup -Name 'ipgroup-<>'
$updatedIpAddresses = $ipGroup.IpAddresses + $newIpRange
Set-AzIpGroup -ResourceGroupName $resourceGroupName -Name $ipGroupName -IpAddresses $updatedIpAddresses
#endregion    