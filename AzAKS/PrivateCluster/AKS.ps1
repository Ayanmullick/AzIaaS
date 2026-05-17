#Conceptualizes cloud in a cluster.
$NameSuffix         = ($Name, $Env, $Loc, $Sr = '<>', 'd', 'c', '01') -join '-'
$Params             = @{Location = 'CentralUS'; Verbose=$true}
$Tags               = @{Division='<>'; Environment='Dev'; AppName= '<>'; Owner= 'Ayan Mullick'}
$RG                 = New-AzResourceGroup @Params -Name ('rg-' + $NameSuffix) -Tag $Tags
$Params            += @{ResourceGroupName  = $RG.ResourceGroupName }



#172.25.22.0/27, 172.25.22.32/27   # /27
$SubnetConfigs = @{('sn-' + $NameSuffix) = '172.25.22.0/26'}.GetEnumerator() | ForEach-Object {New-AzVirtualNetworkSubnetConfig -Name $_.Key -AddressPrefix $_.Value}
$Vnet = New-AzVirtualNetwork @Params -Name ('vn-' + $NameSuffix) -AddressPrefix '172.25.22.0/26' -Subnet $SubnetConfigs
#$Vnet =Get-AzVirtualNetwork -ResourceGroupName rg-<>-d-c-01 -Name ('vn-' + $NameSuffix)

#Peering
$SharedPSub = Get-AzContext -ListAvailable | Where-Object { $_.Subscription.Name -eq '<SharedHubSub>' }
$PeeringParams = @{ResourceGroupName = '<rgvwan>'; VirtualHubName='<vhub>';Name= $Vnet.Name; RemoteVirtualNetworkId=$Vnet.Id; Verbose=$true }    
New-AzVirtualHubVnetConnection @PeeringParams -DefaultProfile $SharedPSub

#region Peering verification
Select-AzSubscription '<SharedHubSub>'
$Vhub = Get-AzVirtualHub -ResourceGroupName '<rgvwan>' -Name '<vhub>'
$vhub.VirtualNetworkConnections|? Name -eq $Vnet.Name|FL

$RT = Get-AzVHubRouteTable -ResourceGroupName '<rgvwan>' -VirtualHubName '<vhub>' -Name DefaultRouteTable
$RT.AssociatedConnections.Where({ $_ -match $vnet.name })
#/subscriptions/<>/resourceGroups/<rgvwan>/providers/Microsoft.Network/virtualHubs/<vhub>/hubVirtualNetworkConnections/vn-<>-d-c-01
$RT.PropagatingConnections.Where({ $_ -match $vnet.name })
#Same
<#Didn't work
Get-AzVHubEffectiveRoute -VirtualHubObject $Vhub -VirtualWanResourceType 'RouteTable' -ResourceId ($Vhub.Id+'hubRouteTables/defaultRouteTable')

Value : []
#>
#Get-AzEffectiveRouteTable  only works for NIC's, not for vnets or subnets
#Get-AzVirtualNetworkSubnetConfig doesn't show effective routes for a subnet unless route resource is attached to subnet

#endregion

#region Route Table
$FW = Get-AzFirewall -ResourceGroupName '<rgvwan>' -DefaultProfile (Get-AzContext -ListAvailable | ? { $_.Subscription.Name -eq '<SharedHubSub>' })
$FW.HubIPAddresses.PrivateIPAddress


$Route = New-AzRouteConfig -Name ('r-' + $NameSuffix) -AddressPrefix '0.0.0.0/0' -NextHopType VirtualAppliance -NextHopIpAddress $FW.HubIPAddresses.PrivateIPAddress

$RouteTable = New-AzRouteTable @Params -Name ('rt-' + $NameSuffix)  -Route $Route

#associate to Servers Subnet
$vnet.Subnets[0].RouteTable = $RouteTable
Set-AzVirtualNetwork -VirtualNetwork $vnet
#Verify
Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $Vnet.Subnets[0].Name|select -ExpandProperty RouteTable
$vnet.Subnets[0].RouteTable
$vnet.Subnets[0].RouteTableText
#endregion



Set-AzContext '<SharedHubSub>'
# Create a private DNS zone for AKS private endpoint (Azure best practice)
#The private DNS zone is mainly to resolve the Kubernetes API server's private endpoint.
$dnsZoneName = "privatelink.$($RG.Location).azmk8s.io"  #privatelink.centralus.azmk8s.io
$dnsZoneRG = '<rgDNS>'
#New-AzPrivateDnsZone -Name $dnsZoneName  -ResourceGroupName $dnsZoneRG -Verbose
$DnsZone = Get-AzPrivateDnsZone -ResourceGroupName $dnsZoneRG -Name $dnsZoneName -DefaultProfile $SharedPSub

$PrivateResolverVnet = Get-AzVirtualNetwork -ResourceGroupName $dnsZoneRG -Name 'vnet-dns-<>'
New-AzPrivateDnsVirtualNetworkLink -ResourceGroupName $dnsZoneRG -ZoneName $dnsZoneName -Name "vnetlink-dns-<>" `
     -VirtualNetworkId $PrivateResolverVnet.Id -EnableRegistration:$false -Verbose


Set-AzContext 'Sub-Business-d'
# Link the DNS zone to the VNet
New-AzPrivateDnsVirtualNetworkLink -ResourceGroupName $dnsZoneRG -ZoneName $dnsZoneName -Name ("vnetlink-" + $NameSuffix) -VirtualNetworkId $Vnet.Id `
      -EnableRegistration -DefaultProfile (Get-AzContext -ListAvailable | ? { $_.Subscription.Name -eq '<SharedHubSub>' }) -Verbose    #:$false

$DnsVnetParams = @{ResourceGroupName=$dnsZoneRG; ZoneName=$dnsZoneName; Name=("vnetlink-" + $NameSuffix); VirtualNetworkId=$Vnet.Id; EnableRegistration=$true}
New-AzPrivateDnsVirtualNetworkLink @DnsVnetParams -DefaultProfile $SharedPSub -Verbose

$Law           = Get-AzOperationalInsightsWorkspace -ResourceGroupName '<rgLAW>' -Name '<LAW>' -DefaultProfile $SharedPSub

$Id            = New-AzUserAssignedIdentity @Params -Name ('uami-' + $NameSuffix)

$ACR =   New-AzContainerRegistry @Params -Name ('acr-' + $NameSuffix).Replace('-', '') -EnableAdminUser -Sku Basic

New-AzKeyVault @Params -Name ('kv-' + $NameSuffix) -EnabledForDiskEncryption -Sku Premium -EnableRbacAuthorization

#AKS cluster's user assigned managed id needs permissions on the DNS zone and on the vnet
<#New-AzRoleAssignment -ObjectId $Id.PrincipalId -RoleDefinitionName 'Private DNS Zone Contributor' -Scope $DnsZone.ResourceId -Verbose
New-AzRoleAssignment -ObjectId $Id.PrincipalId -RoleDefinitionName 'Network Contributor' -Scope $Vnet.Id
New-AzRoleAssignment -ObjectId $Id.PrincipalId -RoleDefinitionName "Key Vault Secrets User" -Scope "<KV resource id>"
New-AzRoleAssignment -ObjectId $Id.PrincipalId -RoleDefinitionName 'Azure Kubernetes Service Contributor Role' -Scope $AKS.Id
#$AKS = Get-AzAksCluster -ResourceGroupName $Rg.ResourceGroupName
#$principalId = $AKS.Identity.UserAssignedIdentities[$Id].PrincipalId
New-AzRoleAssignment -ObjectId $Id.PrincipalId -RoleDefinitionName 'Managed Identity Operator' -Scope $Id.Id
New-AzRoleAssignment -ObjectId $Id.PrincipalId -RoleDefinitionName 'Monitoring Metrics Publisher' -Scope $Id.Id
#>
@(
  'Private DNS Zone Contributor',$DnsZone.ResourceId;   'Network Contributor',$Vnet.Id;     'Key Vault Secrets User','<KV resource id>'
  'Azure Kubernetes Service Contributor Role',$AKS.Id;  'Managed Identity Operator',$Id.Id; 'Monitoring Metrics Publisher',$Id.Id
) | ForEach-Object { New-AzRoleAssignment -ObjectId $Id.PrincipalId -RoleDefinitionName $_[0] -Scope $_[1] -Verbose }



     
$ACR =   New-AzContainerRegistry @Params -Name ('acr-' + $NameSuffix).Replace('-', '') -EnableAdminUser -Sku Basic
#Set-AzAksCluster -ResourceGroupName $RG.ResourceGroupName -Name ('aks-' + $NameSuffix) -AcrNameToAttach $Acr.Name


#region
    -AadProfile $AadProfile
#Connect-Entra -Scopes 'User.ReadWrite.All', 'Directory.AccessAsUser.All' -Verbose
#$Group = New-EntraGroup -DisplayName ('az-' + $Name+'-admin') -MailEnabled $true -SecurityEnabled $true -MailNickname ('az-' + $Name+'-admin') -Description "$Name Azure Admin Group" -Verbose
#New-MgGroup_CreateExpanded: Cannot Create a mail-enabled security groups and or distribution list. 



Connect-ExchangeOnline #-UserPrincipalName 'Ayan.Mullick@<>'
New-DistributionGroup -Name ('az-' + $Name+'-admin') -Alias ('az-' + $Name+'-admin') -Type security -Verbose
Add-DistributionGroupMember -Identity ('az-' + $Name+'-admin') -Member 'Ayan.Mullick@<>' -Verbose

Connect-Entra -Scopes 'User.ReadWrite.All', 'Directory.AccessAsUser.All' -Verbose
$Group = Get-EntraGroup -Filter "displayname eq 'az-<>-admin'"

    
#$AKSAdminGroup=New-AzADGroup -DisplayName myAKSAdminGroup -MailNickname myAKSAdminGroup
$AadProfile=@{ managed=$true; enableAzureRBAC=$true
    adminGroupObjectIDs=[System.Collections.Generic.List[string]]@($group.Id)
}
$AadProfile=[Microsoft.Azure.Management.ContainerService.Models.ManagedClusterAADProfile]$AadProfile


#endregion



$ComputeParams = @{KubernetesVersion='1.32.3'; NodeResourceGroup=('rg-'+$Name+'-aks-'+$Env+'-'+$Loc+'-'+$Sr); NodeCount=1; NodeMaxSurge=3; NodeVmSize='Standard_D2as_v5'; NodePoolMode='System'}
$NwParams = @{DnsNamePrefix=$NameSuffix; NetworkPlugin='azure'; NetworkPolicy='azure'}
$PrivCluParams = @{NodeVnetSubnetID=($Vnet.Subnets[0]).Id; OutboundType='UserDefinedRouting'; ApiServerAccessPrivateDnsZone=$DnsZone.ResourceId
                   EnableApiServerAccessPrivateCluster=$true; EnableApiServerAccessPrivateClusterPublicFqdn=$false}
$GovParams = @{Addon=@("Monitoring", "AzurePolicy", "azure-keyvault-secrets-provider"); WorkspaceResourceId=$LAW.ResourceId; AcrNameToAttach=$Acr.Name; EnableAHUB=$true}

New-AzAksCluster @Params -Name ('aks-' + $NameSuffix) @ComputeParams @NwParams @PrivCluParams @GovParams `
    -EnableRBAC:$true -EnableOIDCIssuer:$true -AssignIdentity $Id.Id -EnableManagedIdentity -AadProfile $AadProfile `
     -Tag $Tags



#region Create AKS metrics alert rules
$email = New-AzActionGroupEmailReceiverObject -Name ('ereciever-' + $NameSuffix) -EmailAddress $group.Mail
$ag = New-AzActionGroup @Params -Location eastus2 -Name ('ag-' + $NameSuffix) -GroupShortName ('ag' + $NameSuffix).Replace('-', '') -EmailReceiver $email

$BaseCriteriaParams = @{TimeAggregation = 'Average'; Operator = 'GreaterThan'}
$BaseRuleParams = @{
    ResourceGroupName   = $rg.ResourceGroupName; TargetResourceScope = $AKS.Id
    WindowSize   = '00:05:00'; Frequency = '00:01:00'; Severity = 3; ActionGroupId = $ag.Id
}

<#
Get-AzMetricDefinition -ResourceId $AKS.Id | 
  Select @{N='Name';E={$_.Name.Value}}, @{N='Desc';E={$_.Name.LocalizedValue}}, Unit, @{N='Agg';E={$_.PrimaryAggregationType}}, 
         @{N='AllAgg';E={$_.SupportedAggregationTypes -join ','}} | ft -Auto
#>

$alerts = @(
    @{ Name = 'HighCpuAKS'; MetricName = 'node_cpu_usage_percentage'; Threshold = 80 },
    @{ Name = 'HighMemAKS'; MetricName = 'node_memory_working_set_percentage'; Threshold = 60 }
)

foreach ($alert in $alerts) {
    $CriteriaParams = @{MetricName = $alert.MetricName; Threshold  = $alert.Threshold }
    $criteria = New-AzMetricAlertRuleV2Criteria @CriteriaParams @BaseCriteriaParams

    $RuleParams = @{Name = $alert.Name; Condition = $criteria }
    Add-AzMetricAlertRuleV2 @RuleParams @BaseRuleParams
}

#endregion

<#Use the same use the same email group for alerting 

Use the same identity for other things.

#>

#region Use the same identity for VMSS
#PowerShell currently lacks a parameter for the kubelet identity

$VMSs = Get-AzVmss -ResourceGroupName 'rg-<>mgd-d-c-01'
$vmss.Identity.UserAssignedIdentities.Clear()
$vmss.Identity.UserAssignedIdentities.Add($Id.Id, @{})
Update-AzVmss -ResourceGroupName $vmss.ResourceGroupName -Name $vmss.Name -VirtualMachineScaleSet $vmss -Verbose
$VMSs = Get-AzVmss -ResourceGroupName 'rg-<>mgd-d-c-01'
$VMSs.Identity.UserAssignedIdentities

#Then manually deleted id: 'aks-<>-d-c-01-agentpool'
#endregion



#region Prepare a JSON payload to set the add-on identity to the existing UAMI
$patch = @{
  properties = @{
    addonProfiles = @{
      azurepolicy = @{ enabled = $true;  identity = @{ resourceId = $Id.Id }  }
      omsagent =    @{enabled = $true; identity = @{ resourceId = $Id.Id }  }
    }
  }
}
$body = $patch | ConvertTo-Json -Depth 10

# Apply the patch using Az REST (API version 2024-10-01 or latest)
$uri = "https://management.azure.com/$($AKS.Id)?api-version=2024-10-01"
Invoke-AzRestMethod -Method PATCH -Uri $uri -Payload $body -Verbose

# Deleted manually 'azurepolicy-aks-<>-d-c-01', 'omsagent-aks-<>-d-c-01'
#endregion


#Despite enabling Azure RBAC the node VM's are not Entra joined
#Enable Azure storage extension
#the alerts created aren't showing on the alerts blade. need to associate.
#add 'kubernetes' not 'kubernetes service'  'baseline standard' azure policy to the cluster.

#Deployment safeguards for AKS
#Enable Defender for containers| K8S API access, Registry access, Azure policy, Agentless scanning for machines, Defendor sensor