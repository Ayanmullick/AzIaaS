#region Get the Azure Firewall policy rule associated with a specific ip group
$resourceGroupName, $firewallPolicyName, $ipGroupName = '<rg-vwan>', 'vhub-prem-pol<>', 'ipgroup<Name>'

# Get the IP group
#$ipGroup = Get-AzIpGroup -ResourceGroupName $resourceGroupName -Name $ipGroupName
# Get the firewall policy rule collection group
$ruleCollectionGroup = Get-AzFirewallPolicyRuleCollectionGroup -ResourceGroupName $resourceGroupName -AzureFirewallPolicyName $firewallPolicyName -Name DefaultNetworkRuleCollectionGroup

#$ruleCollectionGroup.Properties.RuleCollection
$Rules = $ruleCollectionGroup.Properties.RuleCollection.Rules

# Filter rules where SourceIpGroups or DestinationIpGroups contain 'ipgroup<Name>'
#$Rules | Where-Object {$_.SourceIpGroups -match $ipGroupName}
#$Rules | Where-Object {$_.SourceIpGroups -like "*$ipGroupName*"}
#$Rules | Where-Object {$_.SourceIpGroups -like "*$ipGroupName*" -or $_.DestinationIpGroups -like "*$ipGroupName*"}|FT


$Rules.Where({$_.SourceIpGroups -like "*$ipGroupName*" -or $_.DestinationIpGroups -like "*$ipGroupName*"}) |
Select Name, @{N='SourceIpGroups'; E={($_.SourceIpGroups -split '/')[-1]}}, @{N='DestinationIpGroups'; E={($_.DestinationIpGroups -split '/')[-1]}}, Protocols, RuleType |
FT -AutoSize -Wrap





#Application rules
$ipGroupName = 'ipgroup<Name>'

$ApplicationRuleCollectionGroup = Get-AzFirewallPolicyRuleCollectionGroup -ResourceGroupName $resourceGroupName -AzureFirewallPolicyName $firewallPolicyName -Name DefaultApplicationRuleCollectionGroup

$ApplicationRules = $ApplicationRuleCollectionGroup.Properties.RuleCollection.Rules

$apprule = $ApplicationRules.Where({$_.SourceIpGroups -like "*$ipGroupName*" -or $_.DestinationIpGroups -like "*$ipGroupName*"}) 

$apprule|select -Property Name, RuleType, @{N= 'Port' ; E= { $_.Protocols.Port }},"SourceIpGroups",SourceAddresses, TargetUrls, TargetFqdns 
#endregion

#region  Find which IP group \ groups a VM belongs to
$vmName, $resourceGroup = '<AzVmName>', '<AzVmRg>'
$vm = Get-AzVM -Name $vmName -ResourceGroupName $resourceGroup
$nic = Get-AzNetworkInterface -ResourceId $vm.NetworkProfile.NetworkInterfaces[0].Id
$vnet = Get-AzVirtualNetwork | Where-Object { $_.Subnets.Id -contains $nic.IpConfigurations[0].Subnet.Id }
$vnet.AddressSpace.AddressPrefixes


# Get all IP groups in the subscription
$allIpGroups = Get-AzIpGroup

$TargetIP = $vnet.AddressSpace.AddressPrefixes #"172.25.16.240/28"
$MatchingGroups = @()
foreach ($group in $allIpGroups) {
    if ($group.IpAddresses -contains $TargetIP) {
        $MatchingGroups += $group
    }
}

Write-Output "The IP range $TargetIP is found in the following IP Groups:`n"
$MatchingGroups | Select-Object Name, ResourceGroupName, Location, IpAddresses | Format-Table -AutoSize
#endregion




#region Get the Azure Firewall policy rule associated with a specific ip group
$resourceGroupName, $firewallPolicyName, $ipGroupName = '<rg-vwan>', 'vhub-prem-pol<>', 'ipgroup<Name>' # 'ipgroup<>-01' #'ipgroup-avd<>-01' #'ipgroup-<>-01'

# Get the IP group
#$ipGroup = Get-AzIpGroup -ResourceGroupName $resourceGroupName -Name $ipGroupName
#Get-AzIpGroup -Name *-d-*   #Get Dev IP groups
# Get the firewall policy rule collection group
$ruleCollectionGroup = Get-AzFirewallPolicyRuleCollectionGroup -ResourceGroupName $resourceGroupName -AzureFirewallPolicyName $firewallPolicyName -Name DefaultNetworkRuleCollectionGroup

#$ruleCollectionGroup.Properties.RuleCollection
#$ruleCollectionGroup.Properties.RuleCollection|select Name,Priority,@{n='Action';e={$_.action.type}}, RuleCollectionType  #To see the rule collection

$Rules = $ruleCollectionGroup.Properties.RuleCollection.Rules


# Filter rules where SourceIpGroups or DestinationIpGroups contain ipgroup-t-c-01
#$Rules | Where-Object {$_.SourceIpGroups -match $ipGroupName}
#$Rules | Where-Object {$_.SourceIpGroups -like "*$ipGroupName*"}
#$Rules | Where-Object {$_.SourceIpGroups -like "*$ipGroupName*" -or $_.DestinationIpGroups -like "*$ipGroupName*"}|FT


$Rules.Where({$_.SourceIpGroups -like "*$ipGroupName*" -or $_.DestinationIpGroups -like "*$ipGroupName*"}) |
Select Name, @{N='SourceIpGroups'; E={($_.SourceIpGroups -split '/')[-1]}}, @{N='DestinationIpGroups'; E={($_.DestinationIpGroups -split '/')[-1]}}, Protocols, RuleType |
FT -AutoSize -Wrap


#Network rules with '-d-' in name ie. Dev environment
$Rules|? Name -Match '-d-'|
    Select Name, @{N='SourceIpGroups'; E={($_.SourceIpGroups -split '/')[-1]}}, @{N='DestinationIpGroups'; E={($_.DestinationIpGroups -split '/')[-1]}}, Protocols, RuleType |
    FT -AutoSize -Wrap


#Application rules
$ipGroupName = 'ipgroup-avd-<>-01'

$ApplicationRuleCollectionGroup = Get-AzFirewallPolicyRuleCollectionGroup -ResourceGroupName $resourceGroupName -AzureFirewallPolicyName $firewallPolicyName -Name DefaultApplicationRuleCollectionGroup
$ApplicationRules = $ApplicationRuleCollectionGroup.Properties.RuleCollection.Rules
$apprule = $ApplicationRules.Where({$_.SourceIpGroups -like "*$ipGroupName*" -or $_.DestinationIpGroups -like "*$ipGroupName*"}) 

$apprule|select -Property Name, RuleType, @{N= 'Port' ; E= { $_.Protocols.Port }},"SourceIpGroups",SourceAddresses, TargetUrls, TargetFqdns 

#'ipgroup-<>-01' IP group has internet access thru 'app-rule-<>-01'

#endregion



#region 
#region AzFw rule for connectivity to AzPaaS services in Central US| Captures global and regional service tags
$ruleCollectionGroup.Properties.RuleCollection.Rules|? Name -EQ CentralUSPaaSServices  
<#
protocols                : {TCP}
SourceAddresses          : {172.25.16.240/28}
DestinationAddresses     : {Sql.CentralUS, ActionGroup, AppConfiguration, AppServiceManagement…}
SourceIpGroups           : {}
DestinationIpGroups      : {}
DestinationPorts         : {*}
DestinationFqdns         : {}
Description              : 
ProtocolsText            : [
                             "TCP"
                           ]
SourceAddressesText      : [
                             "172.25.16.240/28"
                           ]
DestinationAddressesText : [
                             "ActionGroup","AppConfiguration","AppServiceManagement","AzureActiveDirectory","AzureArcInfrastructure",
                             "AzureDatabricks","AzureDataLake","AzureDataExplorerManagement","AzureDeviceUpdate","AzureDevOps","AzurePortal",
                             "AzureResourceManager","AzureSecurityCenter","AzureSentinel","AzureSiteRecovery","AzureBackup","AzureTrafficManager","AzureUpdateDelivery",
                             "DataFactoryManagement","LogicApps","LogicAppsManagement","KustoAnalytics","Marketplace","PowerBI","SqlManagement",
                             "ApiManagement.CentralUS","AppService.CentralUS","AzureCloud.centralus","AzureContainerRegistry.CentralUS",
                             "AzureCosmosDB.CentralUS","AzureKeyVault.CentralUS","DataFactory.CentralUS","MicrosoftContainerRegistry.CentralUS",
                             "PowerPlatformInfra.CentralUS","ServiceBus.CentralUS","Sql.CentralUS","Storage.CentralUS"
                           ]
SourceIpGroupsText       : []
DestinationIpGroupsText  : []
DestinationPortsText     : [
                             "*"
                           ]
DestinationFqdnsText     : []
Name                     : CentralUSPaaSServices
RuleType                 : NetworkRule
#>
#endregion

#Use 'DestinationAddressesText' from above as $ServiceTags here
$rule = New-AzFirewallNetworkRule -Name "CentralUSPaaSServices" -Description "Allow access to Central US PaaS services" `
            -SourceAddress '172.25.16.240/28' -DestinationAddress $ServiceTags -DestinationPort * -Protocol TCP



$newRule = New-AzFirewallPolicyNetworkRule -Name "AllowWebTraffic" -Description "Allow HTTP traffic" -Protocol "TCP" -SourceAddresses "*" -DestinationAddresses Internet -DestinationPorts "443"            
<# Not applicable here
$AzFW = Get-AzFirewall -ResourceGroupName $resourceGroupName #-Name $FirewallName 
$defaultCollection = $AzFW.NetworkRuleCollections | Where-Object { $_.Name -eq "DefaultNetworkRuleCollectionGroup" }
$defaultCollection.Rules.Add($rule)
Set-AzFirewall -AzureFirewall $azFirewall     
#>

#region adding the rule didn't work
$ruleCollection = $ruleCollectionGroup.Properties.RuleCollection
$updatedRules = [System.Collections.Generic.List[Microsoft.Azure.Commands.Network.Models.PSAzureFirewallPolicyRule]]::new()
$ruleCollection.Rules | ForEach-Object { [void]$updatedRules.Add($_) }

# Add the new rule

$updatedRules = $ruleCollection.Rules + @($Rule)

$ruleCollection.Rules = $updatedRules


$clonedRules = [System.Collections.Generic.List[Object]]::new()
$ruleCollectionGroup.Properties.RuleCollection.Rules | ForEach-Object {
    $clonedRules.Add($_)
}

# Now add your new rule
$clonedRules.Add($rule)

$ruleCollectionGroup.Properties.RuleCollection.Rules = $clonedRules

Set-AzFirewallPolicyRuleCollectionGroup -ResourceGroupName $resourceGroupName `
    -AzureFirewallPolicyName $firewallPolicyName `
    -Name DefaultNetworkRuleCollectionGroup `
    -RuleCollectionGroup $ruleCollectionGroup

Set-AzFirewallPolicyRuleCollectionGroup -ResourceGroupName $resourceGroupName -AzureFirewallPolicyName $firewallPolicyName `
    -Name DefaultNetworkRuleCollectionGroup -RuleCollectionGroup $ruleCollectionGroup
#endregion
    
#endregion




#region Add IP CIDR range to existing IP group
(Get-AzIpGroup -Name 'ipgroup-<>-01').IpAddresses

$ipGroup = Get-AzIpGroup -Name 'ipgroup-<>-01'

#$TargetIP  172.25.21.128/25
$ipGroup.IpAddresses.Add($TargetIP)  #This can directly add the vnet's range|  $TargetIP = $vnet.AddressSpace.AddressPrefixes
Set-AzIpGroup -IpGroup $ipGroup -Verbose

#Address range for vnet-AVD<>-01
$ipGroup.IpAddresses.Add('172.25.18.48/28')
Set-AzIpGroup -IpGroup $ipGroup -Verbose



#endregion




#region get Firewall backend ips
(Get-AzFirewall -ResourceGroupName '<rg-vwan>' -Name "AzureFirewall_vhub<>").HubIPAddresses
<#
PrivateIPAddress PublicIPs
---------------- ---------
'<AzFirewall FrontEnd PrivateIP>'     Microsoft.Azure.Commands.Network.Models.PSAzureFirewallHubPublicIpAddresses

Azure Firewall virtual hub (vWAN) private frontend IP — essentially the stable “ingress/egress” IP of the firewall in the virtual hub dataplane.
#>
(Get-AzVirtualHub -ResourceGroupName '<rg-vwan>' -Name '<vhub name>').AddressPrefix  #172.25.1.0/24

<#The backend SNAT IPs are only discoverable using Kusto
Its for autoscaling built in
https://learn.microsoft.com/en-us/azure/firewall/firewall-performance#total-throughput-for-initial-firewall-deployment
AzureDiagnostics
| where ResourceType == "AZUREFIREWALLS"
| where msg_s contains "172.25.1."
| extend PrivateSNATIP = extract(@"172\.25\.1\.\d+",0,msg_s)
| summarize dcount(PrivateSNATIP), ActiveIPs = make_set(PrivateSNATIP)



dcount_PrivateSNATIP      ActiveIPs
5                         ["<AzFirewall SNAT PrivateIP2>","<AzFirewall SNAT PrivateIP3>","<AzFirewall SNAT PrivateIP4>","<AzFirewall SNAT PrivateIP0>","<AzFirewall SNAT PrivateIP1>"]
#>


#endregion