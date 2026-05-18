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
