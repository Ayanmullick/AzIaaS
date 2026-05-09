Get-AzAksVersion
Get-AzAksCluster -ResourceGroupName '<>'
<#$ClusterSkuName = "Base"              #Autoset
$ClusterSkuTier = "Standard"

"sku": {
                "name": "Base",
                "tier": "Free"
            }

$UpgradeChannel = "patch"
$AzureRBAC = $true                      #Not there
$EnableOmsAgent = $true                 #Autoset
$AvailabilityZones = $true
$SupportPlan = "KubernetesOfficial"     #Autoset
$EnableAadProfile = $true               #Not there
$NodeOSUpgradeChannel = "NodeImage"
$EnablePrivateCluster = $false          #Autoset
$NetworkDataplane = "azure"

$EnableSecretStoreCSIDriver = $false
$VmssNodePool = $true

$EnableWorkloadIdentity = $true


#Image auto updates
$IsImageCleanerEnabled = $true
$ImageCleanerIntervalHours = 168
$EnableAzurePolicy = $true
#>

#region  Public cluster
Register-AzResourceProvider -ProviderNamespace Microsoft.OperationsManagement
Register-AzResourceProvider -ProviderNamespace Microsoft.OperationalInsights

$NameSuffix         = ($Name, $Env, $Loc, $Sr = '<>', 'd', 'c', '01') -join '-'
$Params             = @{Location = 'CentralUS'; Verbose=$true}
$Tags               = @{Division='<>'; Environment='Dev'; AppName= '<>'; Owner= 'Ayan Mullick'}
$RG                 = New-AzResourceGroup @Params -Name ('rg-' + $NameSuffix) -Tag $Tags
$Params            += @{ResourceGroupName  = $RG.ResourceGroupName }

$LAW = New-AzOperationalInsightsWorkspace @Params -Name ('law-' + $NameSuffix) 
     
New-AzAksCluster @Params -Name ('aks-' + $NameSuffix) -KubernetesVersion '1.32.3' `
    -NodeResourceGroup ('rg-'+$Name+'mgd-'+$Env+'-'+$Loc+'-'+$Sr) -NodeCount 1 -NodeMaxSurge 3 -NodeVmSize 'Standard_D2as_v5' -NodePoolMode System `
    -DnsNamePrefix $NameSuffix -NetworkPlugin azure -NetworkPolicy azure `
    -EnableRBAC:$true -EnableOIDCIssuer:$true -EnableManagedIdentity `
    -Addon Monitoring -WorkspaceResourceId $LAW.ResourceId -Tag $Tags
     
$ACR =   New-AzContainerRegistry @Params -Name ('acr-' + $NameSuffix).Replace('-', '') -EnableAdminUser -Sku Basic
Set-AzAksCluster -ResourceGroupName $RG.ResourceGroupName -Name ('aks-' + $NameSuffix) -AcrNameToAttach $Acr.Name
#endregion




#region  Basic Private cluster.  Works
New-AzAksCluster @Params -Name ('aks-' + $NameSuffix) -KubernetesVersion '1.32.3' -NodeResourceGroup ('rg-'+$Name+'mgd-'+$Env+'-'+$Loc+'-'+$Sr) `
    -NodeCount 1 -NodeMaxSurge 3 -NodeVmSize 'Standard_D2as_v5' -NodePoolMode System `
    -DnsNamePrefix $NameSuffix -NetworkPlugin azure -NetworkPolicy azure -NodeVnetSubnetID ($Vnet.Subnets[0]).Id `
    -EnableApiServerAccessPrivateCluster -EnableApiServerAccessPrivateClusterPublicFqdn:$false -OutboundType 'UserDefinedRouting' -ApiServerAccessPrivateDnsZone $DnsZone.ResourceId `
    -EnableRBAC:$true -EnableOIDCIssuer:$true -AssignIdentity $Id.Id -EnableManagedIdentity `
    -Addon Monitoring -WorkspaceResourceId $LAW.ResourceId -Tag $Tags

#New-AzAksCluster: System-assigned managed identity not supported for custom resource PrivateDnsZones. Please use user-assigned managed identity.


#endregion

#Other modules
gcm -Module Microsoft.PowerShell.KubeCtl
            Az.KubernetesConfiguration
            Az.KubernetesConfiguration 
            PSRule.Rules.Kubernetes

