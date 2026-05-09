Get-AzAksVersion -location northcentralus  # Get the AKS versions available in the location

$Name,$Loc = 'myCluster','NorthCentralUS'
$RG        = New-AzResourceGroup -Location $Loc -Name ($Name+'RG') 
$Params    = @{ResourceGroupName  = $RG.ResourceGroupName; Location = $Location; Verbose=$true }

#Uses default parameters. didn't work but created SSH key using the passphrase. And it created an SPN in Entra
New-AzAksCluster @Params -Name $Name -GenerateSshKey  #Enter passphrase:  <>

#region Deploy AKS cluster: V1
#Reusing the generated ssh key didn't work. So, created a new one
ssh-keygen -t rsa -b 4096 -f 'C:\Users\<UserName>\.ssh\id_rsa' -C "Ayan@machine"  #Enter passphrase:  <>
New-AzAksCluster @Params -Name $Name -SshKeyValue (Get-Content 'C:\Users\AyanMullick\.ssh\id_rsa.pub')  #Worked
#Creates a new RG: MC_AKSRG_myCluster_northcentralus, with a Vnet, VMSS, NSG, LB and PIP
#Deleting the RG with the cluster from the portal deletes the other RG as well.
#endregion

#region Explore AKS cluster
Import-AzAksCredential -ResourceGroupName $RG.ResourceGroupName -Name $Name  # Get the credentials of the AKS cluster
Get-AzAksCluster -ResourceGroupName AKSRG -Name mycluster
$Clu.LinuxProfile.Ssh.PublicKeys # Get the public key of the AKS cluster
$Clu.ServicePrincipalProfile # Get the service principal of the AKS cluster. Shows the 'AKS' service principal created in the Entra
$Clu.NetworkProfile.LoadBalancerProfile.EffectiveOutboundIPs # Get the outbound IPs of the AKS cluster
$Clu.NetworkProfile.LoadBalancerProfile.ManagedOutboundIPs
$Clu.SecurityProfile  #Blank since no Defender or KeyVaults were configured

Get-AzAksNodePool -ResourceGroupName $RG.ResourceGroupName -ClusterName $Name # Verify the AKS cluster.  Worked
$NodePool.Type

Get-AzAksUpgradeProfile -ResourceGroupName AKSRG -ClusterName mycluster  #Default
Get-AzAksNodePoolUpgradeProfile -ResourceGroupName AKSRG -ClusterName mycluster -NodePoolName default #Default

Get-AzAksMaintenanceConfiguration -ResourceGroupName aksrg -ResourceName mycluster -Verbose #Didn't work. No output.
Get-AzAksManagedClusterCommandResult #Gets the results of a command which has been run on the Managed Cluster
#endregion

#region Untested
New-AzAksCluster @Params -NodeCount 1 -NodeVmSize "Standard_DS2_v2" -KubernetesVersion "1.13.5" -ServicePrincipalId "http://myAKSServicePrincipal" `
    -ClientSecret "mySecret" -DnsNamePrefix "myAKSDnsPrefix" -AadTenantId "myAadTenantId" -AadClientAppId "myAadClientId" -AadServerAppId "myAadClientId" -AadServerAppSecret "myAadClientSecret" `
    -NetworkPlugin "azure" -NetworkPolicy "azure" -EnableRbac $true -EnableAzureRbac -EnableAzurePolicy $true -EnableAzurePolicyAutoApprove $true -EnableAzurePolicyAssignments $true -EnablePrivateCluster
#endregion

#region Untested
New-AzAksCluster @Params -NodeCount 1 -NodeVmSize "Standard_DS2_v2" -KubernetesVersion "1.13.5" -NodeResourceGroup "myNodeResourceGroup" `
    -ClientSecret "mySecret" -ServicePrincipalSecret "your-client-secret" `
        
-ServicePrincipalId "http://myAKSServicePrincipal" -AadTenantId "myAadTenantId" -AadClientAppId "myAadClientId" -AadServerAppId "myAadClientId" -AadServerAppSecret "myAadClientSecret" -EnableRbac $true -EnableAzureRbac `
    -DnsNamePrefix "myAKSDnsPrefix" -NetworkPlugin "azure" -NetworkPolicy "azure"  -EnableAzurePolicy $true -EnableAzurePolicyAutoApprove $true -EnableAzurePolicyAssignments $true -EnablePrivateCluster
    -AuthorizedIPRanges @("0.0.0.0/0") `
    -AadProfile @{
        "managed" = $true
        "adminGroupObjectIDs" = @("groupObjectId1", "groupObjectId2")
        "enableAzureRBAC" = $true
    } `
    -ApiServerAccessProfile @{
        "authorizedIPRanges" = @("0.0.0.0/0")
        "enablePrivateCluster" = $true
    } `
    -NodeCount 3 `
    -NodeVmSize "Standard_DS2_v2"
    
    -ServiceCidr $ServiceCidr `
    -DnsServiceIp $DnsServiceIP `
    -EnableAutoScaling $EnableAutoScaling `
    -MinCount $MinCount `
    -MaxCount $MaxCount `
    -NodeOsDiskSize $NodeOSDiskSize `
    -EnableOIDC $EnableOIDC `
    -EnableWorkloadIdentity $EnableWorkloadIdentity                 

    -AddonProfile @{
        azurepolicy = @{enabled = $true}
        azureKeyvaultSecretsProvider = @{enabled = $true}
    }
    
    -Tags @{environment = "Production"; owner = "YourName"}
#endregion
