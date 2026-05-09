<#First successful output
New-AzAksCluster @Params -Name ('aks-' + $NameSuffix) -KubernetesVersion '1.32.3' `
>>     -NodeResourceGroup ('rg-'+$Name+'mgd-'+$Env+'-'+$Loc+'-'+$Sr) -NodeCount 1 -NodeMaxSurge 3 -NodeVmSize 'Standard_D2as_v5' `
>>     -NodeVnetSubnetID ($Vnet.Subnets[0]).Id -NetworkPlugin azure -EnableApiServerAccessPrivateCluster -EnableApiServerAccessPrivateClusterPublicFqdn:$false -OutboundType 'UserDefinedRouting' `
>>     -SshKeyValue (Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub" -Raw) -Tag $Tags 
PowerState               : Microsoft.Azure.Commands.Aks.Models.PSPowerState
Sku                      : Microsoft.Azure.Management.ContainerService.Models.ManagedClusterSKU
ExtendedLocation         : 
Identity                 : 
ProvisioningState        : Succeeded
MaxAgentPools            : 100
KubernetesVersion        : 1.32.3
CurrentKubernetesVersion : 1.32.3
DnsPrefix                : aks-m9a43
FqdnSubdomain            : 
Fqdn                     : 
PrivateFQDN              : aks-m9a43-er1wqffc.acfd5671-3606-43a0-8807-7f95235ce36b.privatelink.centralus.azmk8s.io
AzurePortalFQDN          : d6a131086fc45c172962b1d6e1183140-priv.portal.hcp.centralus.azmk8s.io
AgentPoolProfiles        : {default}
LinuxProfile             : Microsoft.Azure.Commands.Aks.Models.PSContainerServiceLinuxProfile
WindowsProfile           : Microsoft.Azure.Commands.Aks.Models.PSManagedClusterWindowsProfile
ServicePrincipalProfile  : Microsoft.Azure.Commands.Aks.Models.PSContainerServiceServicePrincipalProfile
AddonProfiles            : 
PodIdentityProfile       : 
OidcIssuerProfile        : Microsoft.Azure.Management.ContainerService.Models.ManagedClusterOidcIssuerProfile
NodeResourceGroup        : rg-<>mgd-d-c-01
EnableRBAC               : True
EnablePodSecurityPolicy  : 
NetworkProfile           : Microsoft.Azure.Commands.Aks.Models.PSContainerServiceNetworkProfile
AadProfile               : 
AutoUpgradeProfile       : Microsoft.Azure.Commands.Aks.Models.PSManagedClusterAutoUpgradeProfile
AutoScalerProfile        : 
ApiServerAccessProfile   : Microsoft.Azure.Commands.Aks.Models.PSManagedClusterAPIServerAccessProfile
DiskEncryptionSetID      : 
IdentityProfile          : 
PrivateLinkResources     : {management}
DisableLocalAccounts     : 
HttpProxyConfig          : 
SecurityProfile          : Microsoft.Azure.Management.ContainerService.Models.ManagedClusterSecurityProfile
StorageProfile           : Microsoft.Azure.Management.ContainerService.Models.ManagedClusterStorageProfile
PublicNetworkAccess      : 
ResourceGroupName        : rg-<>-d-c-01
Id                       : /subscriptions/<>/resourcegroups/rg-<>-d-c-01/providers/Microsoft.ContainerService/managedClusters/aks-<>-d-c-01
Name                     : aks-<>-d-c-01
Type                     : Microsoft.ContainerService/ManagedClusters
Location                 : centralus
Tags                     : {[AppName, <>], [Division, <>], [Environment, Dev], [Owner, Ayan Mullick]}
#>    

<#-GenerateSshKey
New-AzAksCluster: Default ssh key file C:\Users\<UserName>\.ssh\id_rsa already exists. Please use parameter -SshKeyValue 'C:\Users\<UserName>\.ssh\id_rsa' instead of -GenerateSshKey.
Phrase  1234

#Didn't work
-SshKeyValue (Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub" -Raw)

ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\id_rsa  #had to run  Passphrase:  <>
#>    
<#  /26 is the smallest subnet size allowed.
New-AzAksCluster: Pre-allocated IPs 29 exceeds IPs available 11 in Subnet Cidr 172.25.22.0/28, Subnet Name 'sn-<>-d-c-02'. http://aka.ms/aks/insufficientsubnetsize.
  Surge nodes would also consume the subnet IP space,   please consider use smaller maxSurge or use maxUnavailable, details: aka.ms/aks/maxUnavailable.


#UDR error
New-AzAksCluster: An existing route table has not been associated with subnet 
/subscriptions/<>/resourceGroups/rg-<>-d-c-02/providers/Microsoft.Network/virtualNetworks/vn-<>-d-c-02/subnets/sn-<>-d-c-02. 
Please update the route table association  

#>    
# Output cluster info
$AKS = Get-AzAksCluster -ResourceGroupName $RG.ResourceGroupName -Name ('aks-' + $NameSuffix) #| Format-List
<#
$AKS.StorageProfile.FileCsiDriver

Enabled
-------
   True

$AKS.ApiServerAccessProfile

AuthorizedIPRanges             : 
EnablePrivateCluster           : True
PrivateDNSZone                 : system
EnablePrivateClusterPublicFQDN : False
DisableRunCommand              : 

$AKS.AutoUpgradeProfile

UpgradeChannel
--------------


$AKS.NetworkProfile

NetworkPlugin       : azure
NetworkPolicy       : 
NetworkMode         : 
PodCidr             : 
ServiceCidr         : 10.0.0.0/16
DnsServiceIP        : 10.0.0.10
DockerBridgeCidr    : 
OutboundType        : UserDefinedRouting
LoadBalancerSku     : standard
LoadBalancerProfile : Microsoft.Azure.Commands.Aks.Models.PSManagedClusterLoadBalancerProfile
NatGatewayProfile   : 
PodCidrs            : 
ServiceCidrs        : {10.0.0.0/16}
IpFamilies          : {IPv4}



$AKS.ServicePrincipalProfile

ClientId                             Secret
--------                             ------
'<>' 


$AKS.WindowsProfile

AdminUsername  : azureuser
AdminPassword  : 
LicenseType    : 
EnableCSIProxy : True
GmsaProfile    : 


$AKS.LinuxProfile

AdminUsername Ssh
------------- ---
azureuser     Microsoft.Azure.Commands.Aks.Models.PSContainerServiceSshConfiguration

$AKS.Sku

Name Tier
---- ----
Base Free

$AKS.PowerState        

Code
----
Running
#>

<#Azure CNI Overlay: Don't migrate
IP Allocation: Pods receive IP addresses from a private CIDR range that is logically separate from the VNet hosting the nodes 2.
Networking: Uses an overlay network for pod-to-pod communication within the cluster. Network Address Translation (NAT) is used for communication outside the cluster 2.
Scalability: Saves VNet IP addresses and allows for larger cluster sizes without IP exhaustion issues 2.
Use Case: Ideal for large-scale deployments where IP address conservation and scalability are important
#>

#region connecting to AKS
#Install-WinGetPackage -Id Kubernetes.kubectl -Verbose #Was still needed
Install-AzAksCliTool

Import-AzAksCredential -ResourceGroupName 'rg-<>-d-c-01' -Name 'aks-<>-d-c-01' -Verbose
<#VERBOSE: Performing the operation "Importing Kubernetes config resource." on target "AzureRmKubernetesCredential 'aks-<>-d-c-01' in 'rg-<>-d-c-01'".

Confirm
Do you want to import the Kubernetes config?
[Y] Yes  [N] No  [S] Suspend  [?] Help (default is "Y"): y
VERBOSE: File was not specified. Writing credential to C:\Users\<Username>\.kube\config.
VERBOSE: Fetching the default clusterUser kubectl config
#>
kubectl get nodes

Install-WinGetPackage -Id Microsoft.Azure.Kubelogin -Verbose

kubectl get nodes
To sign in, use a web browser to open the page https://microsoft.com/devicelogin and enter the code EYRGDFJZZ to authenticate.
<#NAME                                STATUS   ROLES    AGE   VERSION
aks-agentpool-14498963-vmss000000   Ready    <none>   73m   v1.32.3
aks-agentpool-14498963-vmss000001   Ready    <none>   69m   v1.32.3
#>

kubectl config get-contexts
kubectl config current-context
kubectl get pods
kubectl get pods -A  #--all-namespaces=true
<#NAMESPACE     NAME                                             READY   STATUS    RESTARTS   AGE
kube-system   ama-logs-mnwfp                                   2/2     Running   0          22m
kube-system   ama-logs-rs-856c4446d9-w4956                     1/1     Running   0          22m
kube-system   azure-cns-f648l                                  1/1     Running   0          22m
kube-system   azure-ip-masq-agent-b7skp                        1/1     Running   0          22m
kube-system   azure-npm-t8h5c                                  1/1     Running   0          22m
kube-system   cloud-node-manager-mv74p                         1/1     Running   0          22m
kube-system   coredns-84d68d4ff-28dt4                          1/1     Running   0          23m
kube-system   coredns-84d68d4ff-fmjct                          1/1     Running   0          22m
kube-system   coredns-autoscaler-79bcb4fd6b-j96z7              1/1     Running   0          23m
kube-system   csi-azuredisk-node-zck88                         3/3     Running   0          22m
kube-system   csi-azurefile-node-h2wtd                         3/3     Running   0          22m
kube-system   konnectivity-agent-794d6945bb-85td4              1/1     Running   0          22m
kube-system   konnectivity-agent-794d6945bb-wrhqt              1/1     Running   0          23m
kube-system   konnectivity-agent-autoscaler-844df78bbd-hprgp   1/1     Running   0          23m
kube-system   kube-proxy-jhlw5                                 1/1     Running   0          22m
kube-system   metrics-server-59d6dfb75d-g6cqg                  2/2     Running   0          22m
kube-system   metrics-server-59d6dfb75d-xwf4r                  2/2     Running   0          22m
#>
kubectl get deployments

kubectl create deployment hello-app --image=mcr.microsoft.com/azuredocs/aks-helloworld:v1 --v=6
<#I0507 13:18:09.888689    6260 loader.go:402] Config loaded from file:  C:\Users\<UserName>\.kube\config
I0507 13:18:09.889719    6260 envvar.go:172] "Feature gate default state" feature="ClientsAllowCBOR" enabled=false
I0507 13:18:09.889719    6260 envvar.go:172] "Feature gate default state" feature="ClientsPreferCBOR" enabled=false
I0507 13:18:09.889719    6260 envvar.go:172] "Feature gate default state" feature="InformerResourceVersion" enabled=false
I0507 13:18:09.889719    6260 envvar.go:172] "Feature gate default state" feature="InOrderInformers" enabled=true
I0507 13:18:09.890243    6260 envvar.go:172] "Feature gate default state" feature="WatchListClient" enabled=false
I0507 13:18:09.995231    6260 round_trippers.go:632] "Response" verb="POST" url="https://aks-<>-d-c-02-dns-dimlnm0g.hcp.centralus.azmk8s.io:443/apis/apps/v1/namespaces/default/deployments?fieldManager=kubectl-create&fieldValidation=Strict" status="201 Created" milliseconds=97
deployment.apps/hello-app created
#>
kubectl get pods
#NAME                        READY   STATUS              RESTARTS   AGE
#hello-app-8887bc7fc-5stgf   0/1     ContainerCreating   0          11s
kubectl expose deployment hello-app --type=LoadBalancer --port=80 --target-port=80 --v=6
<#I0507 13:19:57.777467   15788 loader.go:402] Config loaded from file:  C:\Users\<UserName>\.kube\config
I0507 13:19:57.779687   15788 envvar.go:172] "Feature gate default state" feature="InOrderInformers" enabled=true
I0507 13:19:57.783808   15788 envvar.go:172] "Feature gate default state" feature="WatchListClient" enabled=false
I0507 13:19:57.784057   15788 envvar.go:172] "Feature gate default state" feature="ClientsAllowCBOR" enabled=false
I0507 13:19:57.784057   15788 envvar.go:172] "Feature gate default state" feature="ClientsPreferCBOR" enabled=false
I0507 13:19:57.784057   15788 envvar.go:172] "Feature gate default state" feature="InformerResourceVersion" enabled=false
I0507 13:19:57.894740   15788 round_trippers.go:632] "Response" verb="GET" url="https://aks-<>-d-c-02-dns-dimlnm0g.hcp.centralus.azmk8s.io:443/apis/apps/v1/namespaces/default/deployments/hello-app" status="200 OK" milliseconds=90
I0507 13:19:57.933649   15788 round_trippers.go:632] "Response" verb="POST" url="https://aks-<>-d-c-02-dns-dimlnm0g.hcp.centralus.azmk8s.io:443/api/v1/namespaces/default/services?fieldManager=kubectl-expose" status="201 Created" milliseconds=29
service/hello-app exposed
#>

kubectl get service
#NAME           TYPE           CLUSTER-IP    EXTERNAL-IP       PORT(S)        AGE
#hello-app      LoadBalancer   10.0.7.148    52.185.103.64     80:30844/TCP   11s
#kodekloudapp   LoadBalancer   10.0.225.93   172.168.209.237   80:30970/TCP   41m
#kubernetes     ClusterIP      10.0.0.1      <none>            443/TCP        167m

kubectl get deployments --all-namespaces=true
<#NAMESPACE           NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
default             hello-app                             1/1     1            1           95m
gatekeeper-system   gatekeeper-audit                      1/1     1            1           4h21m
gatekeeper-system   gatekeeper-controller                 2/2     2            2           4h21m
kube-system         ama-logs-rs                           1/1     1            1           4h17m
kube-system         azure-policy                          1/1     1            1           4h21m
kube-system         azure-policy-webhook                  1/1     1            1           4h21m
kube-system         azure-wi-webhook-controller-manager   2/2     2            2           4h19m
kube-system         coredns                               2/2     2            2           4h21m
kube-system         coredns-autoscaler                    1/1     1            1           4h21m
kube-system         eraser-controller-manager             1/1     1            1           4h20m
kube-system         konnectivity-agent                    2/2     2            2           4h21m
kube-system         konnectivity-agent-autoscaler         1/1     1            1           4h21m
kube-system         metrics-server                        2/2     2            2           4h21m
#>

kubectl get service --all-namespaces=true
<#
NAMESPACE     NAME                          TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)         AGE
default       kubernetes                    ClusterIP   10.0.0.1       <none>        443/TCP         28m
kube-system   kube-dns                      ClusterIP   10.0.0.10      <none>        53/UDP,53/TCP   27m
kube-system   metrics-server                ClusterIP   10.0.138.247   <none>        443/TCP         27m
kube-system   npm-metrics-cluster-service   ClusterIP   10.0.69.199    <none>        9000/TCP        27m
#>

Install-WinGetPackage Openlens
#Reads available kubernetes contexts by default. One can click on the one 



Install-Package YamlDotNet
Install-PSResource -Name PSKubectl -Scope AllUsers -Verbose
Install-PSResource -Name PSKubectlCompletion -Scope AllUsers -Verbose
Get-KubeConfig


Install-PSResource -Name Az.KubernetesConfiguration -Scope AllUsers -Verbose

Install-PSResource -Name  PSRule.Rules.Kubernetes -Scope AllUsers -Verbose
gcm -Module  PSRule.Rules.Kubernetes  #No cmdlets

Install-PSResource -Name Az.KubernetesRuntime -Scope AllUsers
Install-PSResource -Name Az.ConnectedKubernetes -Scope AllUsers
Install-PSResource -Name psk8s -Scope AllUsers


$pods = kubectl get pods -n default -o json | ConvertFrom-Json
$pods.items | Select-Object @{Name="Name";Expression={$_.metadata.name}}, @{Name="Status";Expression={$_.status.phase}}

<#Name                      Status
----                      ------
hello-app-8887bc7fc-5stgf Running
#>
#v2
(kubectl get pods -n default -o json | ConvertFrom-Json).items | Select @{N="Name";E={$_.metadata.name}}, @{N="Status";E={$_.status.phase}}

kubectl get pods --all-namespaces -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,CONTAINERS:.spec.containers[*].name,IMAGES:.spec.containers[*].image"
<#
NAMESPACE     NAME                                             STATUS    CONTAINERS                                       IMAGES
default       hello-app-8887bc7fc-m4mrf                        Running   aks-helloworld                                   mcr.microsoft.com/azuredocs/aks-helloworld:v1
kube-system   ama-logs-mnwfp                                   Running   ama-logs,ama-logs-prometheus                     mcr.microsoft.com/azuremonitor/containerinsights/ciprod:3.1.26,mcr.microsoft.com/azuremonitor/containerinsights/ciprod:3.1.26
kube-system   ama-logs-rs-856c4446d9-w4956                     Running   ama-logs                                         mcr.microsoft.com/azuremonitor/containerinsights/ciprod:3.1.26
kube-system   azure-cns-f648l                                  Running   pause                                            mcr.microsoft.com/oss/kubernetes/pause:3.6
kube-system   azure-ip-masq-agent-b7skp                        Running   azure-ip-masq-agent                              mcr.microsoft.com/oss/v2/azure/ip-masq-agent-v2:v0.1.15-2
kube-system   azure-npm-t8h5c                                  Running   azure-npm                                        mcr.microsoft.com/containernetworking/azure-npm:v1.5.45
kube-system   cloud-node-manager-mv74p                         Running   cloud-node-manager                               mcr.microsoft.com/oss/kubernetes/azure-cloud-node-manager:v1.32.3
kube-system   coredns-84d68d4ff-28dt4                          Running   coredns                                          mcr.microsoft.com/oss/v2/kubernetes/coredns:v1.11.3-6
kube-system   coredns-84d68d4ff-fmjct                          Running   coredns                                          mcr.microsoft.com/oss/v2/kubernetes/coredns:v1.11.3-6
kube-system   coredns-autoscaler-79bcb4fd6b-j96z7              Running   autoscaler                                       mcr.microsoft.com/oss/v2/kubernetes/autoscaler/cluster-proportional-autoscaler:v1.9.0-1
kube-system   csi-azuredisk-node-zck88                         Running   liveness-probe,node-driver-registrar,azuredisk   mcr.microsoft.com/oss/kubernetes-csi/livenessprobe:v2.15.0,mcr.microsoft.com/oss/kubernetes-csi/csi-node-driver-registrar:v2.13.0,mcr.microsoft.com/oss/kubernetes-csi/azuredisk-csi:v1.32.1
kube-system   csi-azurefile-node-h2wtd                         Running   liveness-probe,node-driver-registrar,azurefile   mcr.microsoft.com/oss/kubernetes-csi/livenessprobe:v2.15.0,mcr.microsoft.com/oss/kubernetes-csi/csi-node-driver-registrar:v2.13.0,mcr.microsoft.com/oss/kubernetes-csi/azurefile-csi:v1.32.1
kube-system   konnectivity-agent-794d6945bb-85td4              Running   konnectivity-agent                               mcr.microsoft.com/oss/kubernetes/apiserver-network-proxy/agent:v0.30.3-hotfix.20240819
kube-system   konnectivity-agent-794d6945bb-wrhqt              Running   konnectivity-agent                               mcr.microsoft.com/oss/kubernetes/apiserver-network-proxy/agent:v0.30.3-hotfix.20240819
kube-system   konnectivity-agent-autoscaler-844df78bbd-hprgp   Running   autoscaler                                       mcr.microsoft.com/oss/v2/kubernetes/autoscaler/cluster-proportional-autoscaler:v1.9.0-1
kube-system   kube-proxy-jhlw5                                 Running   kube-proxy                                       mcr.microsoft.com/oss/kubernetes/kube-proxy:v1.32.3
kube-system   metrics-server-59d6dfb75d-g6cqg                  Running   metrics-server-vpa,metrics-server                mcr.microsoft.com/oss/v2/kubernetes/autoscaler/addon-resizer:v1.8.23-2,mcr.microsoft.com/oss/v2/kubernetes/metrics-server:v0.7.2-6
kube-system   metrics-server-59d6dfb75d-xwf4r                  Running   metrics-server-vpa,metrics-server                mcr.microsoft.com/oss/v2/kubernetes/autoscaler/addon-resizer:v1.8.23-2,mcr.microsoft.com/oss/v2/kubernetes/metrics-server:v0.7.2-6
#>



$pods = kubectl get pods -A -o json | ConvertFrom-Json   #-A = --all-namespaces
$pods.items | % {
  [pscustomobject]@{
    NAMESPACE  = $_.metadata.namespace
    NAME       = $_.metadata.name
    READY      = ($_.status.containerStatuses | % { $_.ready }) -join ","
    STATUS     = $_.status.phase
    RESTARTS   = ($_.status.containerStatuses | % { $_.restartCount }) -join ","
    AGE        = ([datetime]$_.metadata.creationTimestamp).ToString("ddd M.d H:m")
    CONTAINERS = ($_.spec.containers | % { $_.name }) -join ","
    IMAGES     = ($_.spec.containers | % { $_.image }) -join ","
  }
} | Format-Table -AutoSize

$pods = kubectl get pods -A -o json | ConvertFrom-Json
$pods.items | 
  FT @{N='Namespace';  E={$_.metadata.namespace};W=12},   @{N='Name';E={$_.metadata.name};W=30},
     @{N='Containers'; E={($_.spec.containers | % { $_.name }) -join ","}; W=20},   @{N='Images';E={($_.spec.containers | % { $_.image }) -join ","}; W=70},   
     @{N='Ready';      E={($_.status.containerStatuses | % { $_.ready }) -join ","}; W=10},   @{N='Status';   E={$_.status.phase};      W=10},
     @{N='Restarts';   E={($_.status.containerStatuses | % { $_.restartCount }) -join ","}; W=10},
     @{N='Age';        E={([datetime]$_.metadata.creationTimestamp).ToString("ddd M.d H:m")}; W=15}
<#Namespace    Name                           Containers           Images                                                                 Ready      Status     Restarts   Age
---------    ----                           ----------           ------                                                                 -----      ------     --------   ---
default      hello-app-8887bc7fc-m4mrf      aks-helloworld       mcr.microsoft.com/azuredocs/aks-helloworld:v1                          True       Running    0          Wed 5.7 20:9
kube-system  ama-logs-mnwfp                 ama-logs,ama-logs-p… mcr.microsoft.com/azuremonitor/containerinsights/ciprod:3.1.26,mcr.mi… True,True  Running    0,0        Wed 5.7 19:40
kube-system  ama-logs-rs-856c4446d9-w4956   ama-logs             mcr.microsoft.com/azuremonitor/containerinsights/ciprod:3.1.26         True       Running    0          Wed 5.7 19:40
kube-system  azure-cns-f648l                pause                mcr.microsoft.com/oss/kubernetes/pause:3.6                             True       Running    0          Wed 5.7 19:40
kube-system  azure-ip-masq-agent-b7skp      azure-ip-masq-agent  mcr.microsoft.com/oss/v2/azure/ip-masq-agent-v2:v0.1.15-2              True       Running    0          Wed 5.7 19:40
kube-system  azure-npm-t8h5c                azure-npm            mcr.microsoft.com/containernetworking/azure-npm:v1.5.45                True       Running    0          Wed 5.7 19:40
kube-system  cloud-node-manager-mv74p       cloud-node-manager   mcr.microsoft.com/oss/kubernetes/azure-cloud-node-manager:v1.32.3      True       Running    0          Wed 5.7 19:40
kube-system  coredns-84d68d4ff-28dt4        coredns              mcr.microsoft.com/oss/v2/kubernetes/coredns:v1.11.3-6                  True       Running    0          Wed 5.7 19:40
kube-system  coredns-84d68d4ff-fmjct        coredns              mcr.microsoft.com/oss/v2/kubernetes/coredns:v1.11.3-6                  True       Running    0          Wed 5.7 19:40
kube-system  coredns-autoscaler-79bcb4fd6b… autoscaler           mcr.microsoft.com/oss/v2/kubernetes/autoscaler/cluster-proportional-a… True       Running    0          Wed 5.7 19:40
kube-system  csi-azuredisk-node-zck88       liveness-probe,node… mcr.microsoft.com/oss/kubernetes-csi/livenessprobe:v2.15.0,mcr.micros… True,True… Running    0,0,0      Wed 5.7 19:40
kube-system  csi-azurefile-node-h2wtd       liveness-probe,node… mcr.microsoft.com/oss/kubernetes-csi/livenessprobe:v2.15.0,mcr.micros… True,True… Running    0,0,0      Wed 5.7 19:40
kube-system  konnectivity-agent-6798b8db44… konnectivity-agent   mcr.microsoft.com/oss/kubernetes/apiserver-network-proxy/agent:v0.30.… True       Running    0          Wed 5.7 20:25
kube-system  konnectivity-agent-6798b8db44… konnectivity-agent   mcr.microsoft.com/oss/kubernetes/apiserver-network-proxy/agent:v0.30.… True       Running    0          Wed 5.7 20:25
kube-system  konnectivity-agent-autoscaler… autoscaler           mcr.microsoft.com/oss/v2/kubernetes/autoscaler/cluster-proportional-a… True       Running    0          Wed 5.7 19:40
kube-system  kube-proxy-jhlw5               kube-proxy           mcr.microsoft.com/oss/kubernetes/kube-proxy:v1.32.3                    True       Running    0          Wed 5.7 19:40
kube-system  metrics-server-59d6dfb75d-g6c… metrics-server-vpa,… mcr.microsoft.com/oss/v2/kubernetes/autoscaler/addon-resizer:v1.8.23-… True,True  Running    0,0        Wed 5.7 19:40
kube-system  metrics-server-59d6dfb75d-xwf… metrics-server-vpa,… mcr.microsoft.com/oss/v2/kubernetes/autoscaler/addon-resizer:v1.8.23-… True,True  Running    0,0        Wed 5.7 19:40
#>   
   


#endregion


#region  Private AKS connection
kubectl expose deployment hello-app --port=80 --target-port=80 --name=hello-app-service --type=ClusterIP --v=6 #Only for AKS internal access
kubectl delete service hello-app-service



kubectl expose deployment hello-app --port=80 --target-port=80 --name=hello-app-service --type=NodePort --v=6
kubectl get service

<#kubectl get service
NAME                TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
hello-app-service   NodePort    10.0.92.65   <none>        80:30332/TCP   3s
kubernetes          ClusterIP   10.0.0.1     <none>        443/TCP        23m
#>

Resolve-DnsName -Name '<>-d-c-01-rg3hkp8x.privatelink.centralus.azmk8s.io'

Test-NetConnection 172.25.22.11 -Port 30332  #TcpTestSucceeded : True

curl http://172.25.22.11:30332
iwr http://172.25.22.11:30332
(iwr http://172.25.22.11:30332).Content
#endregion


#region Deploy the AzPowerShell image and SSH into it to test connectivity
kubectl apply -f pshell-http.yaml
kubectl expose deployment pshell-http --type=NodePort --port=80 --target-port=8080
kubectl get svc pshell-http
curl http://172.25.22.11:32603
(iwr http://172.25.22.11:32603).RawContent



kubectl get pods -l app=pshell-http
kubectl exec -it pshell-http-5dd7665496-hjq6t -- pwsh  #puts you inside the container.

hostname
Resolve-DnsName microsoft.com  #doesn't work
iwr https://microsoft.com  #should validate outgoing internet connectivity
#endregion


#region connect to the node to get images size etc
kubectl get nodes -o wide  #get the private ip of the node.
#Had to get "$env:USERPROFILE\.ssh\id_rsa.pub"  the public key is needed to ssh into the node
#Had to use the original passphrase used while running 'ssh-keygen'
Enter-AzVM -Ip 172.25.22.11 -LocalUser azureuser -PublicKeyFile ./id_rsa.pub
ssh azureuser@172.25.22.11    #This puts you into the node.


sudo crictl images  #Shows the size of the images as pulled from their source 
#Install PowerShell
sudo apt update
sudo apt install snapd
sudo snap install powershell --classic

(Invoke-WebRequest ifconfig.me/ip).Content.Trim()  #<>  #Should give you Azure Firewall IP

#endregion