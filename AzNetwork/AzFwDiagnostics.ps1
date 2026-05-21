



<#The windows admin center virtual machine extension is currently not compatible with Azure firewall . 
#In spite of creating dnet rules for 6516 port one is unable to get to the admin center console because of some complexity related to DNS entries . 
#However, one is able to install windows admin center inside of the virtual machine and get to it using the Azure firewall DNAT rule . 

Name                     ResourceGroupName ResourceType                                 Location
----                     ----------------- ------------                                 --------
NvStateTstVMD            NVSTATETSTRG      Microsoft.Compute/disks                      northcentralus
NvStateTstVM             NvStateTstRG      Microsoft.Compute/virtualMachines            northcentralus
NvStateTstVM/AdminCenter NvStateTstRG      Microsoft.Compute/virtualMachines/extensions northcentralus
NvStateTstVM/BGInfo      NvStateTstRG      Microsoft.Compute/virtualMachines/extensions northcentralus
NvStateTstFw             NvStateTstRG      Microsoft.Network/azureFirewalls             northcentralus
NvStateTstFwP            NvStateTstRG      Microsoft.Network/firewallPolicies           northcentralus
NvStateTstVMNic          NvStateTstRG      Microsoft.Network/networkInterfaces          northcentralus
NvStateTstNSG            NvStateTstRG      Microsoft.Network/networkSecurityGroups      northcentralus  #Should not be needed
NvStateTstFwPIP          NvStateTstRG      Microsoft.Network/publicIPAddresses          northcentralus
NvStateTstVMPIP1         NvStateTstRG      Microsoft.Network/publicIPAddresses          northcentralus  #Should not be needed
NvStateTstFwRouteTable   NvStateTstRG      Microsoft.Network/routeTables                northcentralus
NvStateTstvNet           NvStateTstRG      Microsoft.Network/virtualNetworks            northcentralus
#>



#region  Kusto to query if traffic to a specific outgoing IP is allowed.
AzureDiagnostics
| where SourceIP contains "172.25.20.143"
| where Fqdn_s contains ""
| where DestinationPort_d == "1688"
| project SourceIP, DestinationIp_s, DestinationPort_d, Action_s, Fqdn_s, Timestamp_t

<#

SourceIP	DestinationIp_s	DestinationPort_d	Action_s	Fqdn_s	Timestamp_t [UTC]
172.25.20.143	20.118.99.224	1688	Allow		
SourceIP	172.25.20.143				
DestinationIp_s	20.118.99.224				
DestinationPort_d	1688				
Action_s	Allow
#>

AzureDiagnostics
| where SourceIP contains "172.25.5.43"
| where Fqdn_s contains "microsoft"
| project SourceIP, SourcePort_d, DestinationIp_s, DestinationPort_d, Action_s, Fqdn_s




let targetIPs = dynamic(["64.94.84.217", "138.199.156.22", "216.245.184.181", "212.237.217.182", "168.11.96.41"]);
AzureDiagnostics
| where ResourceType == "AZUREFIREWALLS"
| where Category == "AZFWNetworkRule"
| where SourceIP in (targetIPs) or DestinationIp_s in (targetIPs)
| project TimeGenerated, SourceIP, DestinationIp_s, DestinationPort_d, Protocol_s, Action_s, msg_s
| order by TimeGenerated desc





let targetIPs = dynamic([
  "64.94.84.217", 
  "138.199.156.22", 
  "216.245.184.181", 
  "212.237.217.182", 
  "168.11.96.41"
]);
let targetDomains = dynamic([
  "www.cwls29.top",
  "kennedy-throwing-knock-whats.trycloudflare.com",
  "oclc-publishing-individual-maps.trycloudflare.com",
  "time-syncmicrosoft.com",
  "microsoft-jplcloud.com",
  "assets-msnds.org",
  "periodic-priest-games-assessed.trycloudflare.com",
  "sync-time-win.live",
  "sublime-forecasts-pale-scored.trycloudflare.com",
  "washing-cartridges-watts-flags.trycloudflare.com",
  "investigators-boxing-trademark-threatened.trycloudflare.com",
  "fotos-phillips-princess-baker.trycloudflare.com",
  "casting-advisors-older-invitations.trycloudflare.com",
  "complement-parliamentary-chairs-hc.trycloudflare.com"
]);
AzureDiagnostics
| where ResourceType == "AZUREFIREWALLS"
| where Category in ("AZFWApplicationRule", "AZFWNetworkRule", "AZFWNatRule")
| where SourceIP in (targetIPs)
   or DestinationIp_s in (targetIPs)
   or TargetUrl_s has_any (targetDomains)
   or Fqdn_s has_any (targetDomains)
| project TimeGenerated, Category, SourceIP, DestinationIp_s, TargetUrl_s, Fqdn_s, Action_s, msg_s, Rule_s
| order by TimeGenerated desc




#This checks in the Azure firewall and Azure application gateway diagnostics logs
let targetIPs = dynamic([
  "64.94.84.217", 
  "138.199.156.22", 
  "216.245.184.181", 
  "212.237.217.182", 
  "168.11.96.41"
]);

let targetDomains = dynamic([
  "www.cwls29.top",
  "kennedy-throwing-knock-whats.trycloudflare.com",
  "oclc-publishing-individual-maps.trycloudflare.com",
  "time-syncmicrosoft.com",
  "microsoft-jplcloud.com",
  "assets-msnds.org",
  "periodic-priest-games-assessed.trycloudflare.com",
  "sync-time-win.live",
  "sublime-forecasts-pale-scored.trycloudflare.com",
  "washing-cartridges-watts-flags.trycloudflare.com",
  "investigators-boxing-trademark-threatened.trycloudflare.com",
  "fotos-phillips-princess-baker.trycloudflare.com",
  "casting-advisors-older-invitations.trycloudflare.com",
  "complement-parliamentary-chairs-hc.trycloudflare.com"
]);

AzureDiagnostics
| where ResourceType in~ ("AZUREFIREWALLS", "APPLICATIONGATEWAYS")
| where Category in~ ("AZFWApplicationRule", "AZFWNetworkRule", "AZFWNatRule", "ApplicationGatewayAccessLog")
| extend 
    SourceIP_s = tostring(SourceIP),
    DestinationIp_s = tostring(DestinationIp_s),
    TargetUrl_s = tostring(TargetUrl_s),
    Fqdn_s = tostring(Fqdn_s)
| where SourceIP_s in (targetIPs)
    or DestinationIp_s in (targetIPs)
    or TargetUrl_s has_any (targetDomains)
    or Fqdn_s has_any (targetDomains)
| project TimeGenerated, ResourceType, Category, SourceIP_s, DestinationIp_s, TargetUrl_s, Fqdn_s, Action_s, msg_s, Rule_s
| order by TimeGenerated desc









AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS" and Category == "ApplicationGatewayFirewallLog"
| where action_s == "Detected"
| project TimeGenerated, clientIP_s, requestUri_s, ruleName_s, ruleGroup_s, details_data_s, hostname_s, httpMethod_s, action_s
| order by TimeGenerated desc





#Malicious IP connections for a specific VM's agent
VMConnection
| where AgentId =~ 'd3a2e542-c44c-04a6-1a26-343c56d4b211'
| where MaliciousIp != ""


#If you want a list of the actual malicious IPs per computer, use:
VMConnection
| where MaliciousIp != ""
| summarize MaliciousIPs = make_set(MaliciousIp), Count = count() by Computer
| order by Count desc









#fluentbit_CL is the table for a Palo Saas NGFW




#endregion

Get-AzIpGroup -ResourceGroupName '<rg-vwan>' -Name '<ipgroup-webservers>'|fl *


$resourceGroupName = '<rg-vwan>'
$firewallPolicyName = "vhub-pr"
$firewallPolicyName = 'vhub-prem-pol<>'
$ipGroupName = '<ipgroup-webservers>'
$firewallPolicy = Get-AzFirewallPolicy -ResourceGroupName $resourceGroupName -Name $firewallPolicyName



#region Kusto query for AzFW rules hitting an AzVM
AzureDiagnostics
| where Category == "AzureFirewallNetworkRule"
| where msg_s has "<SourceAzVmPrivateIp>" 
| parse msg_s with "Deny " protocol " request from " sourceIP ":" sourcePort " to " destIP ":" destPort ". Rule*" 
| project TimeGenerated, protocol, sourceIP, sourcePort, destIP, destPort, msg_s
| order by TimeGenerated desc
#endregion