# AKS Private Cluster Component Comparison — Script-Aware Matrix

This matrix compares common Kubernetes / OSS [Open Source System]components with the Azure-native equivalents used or implied by the AKS private cluster PowerShell script.

\---

## 1\. Mandatory AKS / Kubernetes Components

|Status in Your Script|OSS Component|Purpose|Azure / AKS Equivalent|Notes|
|-|-|-|-|-|
|Deployed automatically|kube-apiserver|Main Kubernetes control plane endpoint|AKS-managed API server|Created by New-AzAksCluster. Private API enabled using EnableApiServerAccessPrivateCluster = true.|
|Deployed automatically|etcd|Stores Kubernetes cluster state|AKS-managed etcd|Created automatically by New-AzAksCluster; not directly configured in the script.|
|Deployed automatically|kube-scheduler|Places pods on nodes|AKS-managed scheduler|Created automatically by New-AzAksCluster; not directly configured in the script.|
|Deployed automatically|kube-controller-manager|Reconciles desired cluster state|AKS-managed controller manager|Created automatically by New-AzAksCluster; not directly configured in the script.|
|Deployed automatically|cloud-controller-manager|Integrates Kubernetes with Azure resources|AKS Azure cloud provider integration|Created automatically by New-AzAksCluster; Azure integration implied by AKS.|
|Deployed automatically|kubelet|Node agent that runs pods|AKS node component|Created as part of the AKS node pool through New-AzAksCluster.|
|Deployed automatically|containerd|Runs containers on nodes|containerd on AKS nodes|Managed by AKS node image; not directly configured in the script.|
|Deployed automatically|CoreDNS|Internal cluster DNS and service discovery|AKS-managed CoreDNS|Created automatically by AKS; private DNS for API server configured separately using ApiServerAccessPrivateDnsZone.|
|Deployed automatically|kube-proxy / dataplane|Kubernetes service networking|AKS networking dataplane|Implied by New-AzAksCluster with NetworkPlugin = azure.|
|Deployed|Kubernetes node pool|Hosts critical system pods|AKS system node pool|Configured with NodePoolMode = System, NodeCount = 1, and NodeVmSize = Standard\_D2as\_v5.|

\---

## 2\. Other Foundational Azure Components

|Status in Your Script|OSS Component|Purpose|Azure-Native Equivalent|Notes|
|-|-|-|-|-|
|Deployed|N/A - Azure resource|Logical container for Azure resources|Azure Resource Group|Created using New-AzResourceGroup with Name = rg- + NameSuffix.|
|Deployed|N/A - Azure metadata|Ownership, billing, cost, and governance metadata|Azure Tags|Configured using the Tags hashtable with Division, Environment, AppName, and Owner.|
|Deployed|N/A - Azure identity|Identity used by AKS and related components|Azure User Assigned Managed Identity|Created using New-AzUserAssignedIdentity and passed to AKS using AssignIdentity.|
|Deployed|Docker Registry / Harbor|Private container image registry|Azure Container Registry|Created using New-AzContainerRegistry with Sku = Basic.|
|Deployed|imagePullSecrets / registry auth|Allows AKS to pull private container images|AKS ACR attach / managed identity-based pull|Configured using AcrNameToAttach = Acr.Name in GovParams.|
|Deployed|HashiCorp Vault / Kubernetes Secrets|Central store for secrets, keys, and certificates|Azure Key Vault|Created using New-AzKeyVault with EnableRbacAuthorization.|
|Integrated|ELK / OpenSearch / Loki|Central log and monitoring workspace|Azure Monitor Logs / Log Analytics Workspace|Existing workspace retrieved using Get-AzOperationalInsightsWorkspace and passed as WorkspaceResourceId.|
|Deployed|Alertmanager receiver|Alert notification target|Azure Monitor Action Group|Created using New-AzActionGroup and New-AzActionGroupEmailReceiverObject.|
|Deployed|Prometheus alert rules / Alertmanager|CPU and memory alerting|Azure Monitor Metric Alerts|Created using Add-AzMetricAlertRuleV2 with metrics node\_cpu\_usage\_percentage and node\_memory\_working\_set\_percentage.|
|Enabled|N/A - Azure licensing feature|Licensing optimization where applicable|Azure Hybrid Benefit|Enabled through EnableAHUB = true in GovParams.|

\---

## 3\. Networking Components

|Status in Your Script|OSS Component|Purpose|Azure-Native Equivalent|Notes|
|-|-|-|-|-|
|Deployed|CNI networking model|Network boundary for AKS resources|Azure Virtual Network|Created using New-AzVirtualNetwork with AddressPrefix 172.25.22.0/26.|
|Deployed|CNI subnet / node subnet|Hosts AKS node pool resources|Azure VNet subnet|Created using New-AzVirtualNetworkSubnetConfig with AddressPrefix 172.25.22.0/26.|
|Deployed|CNI plugin|Kubernetes pod and node networking|Azure CNI|Configured using NetworkPlugin = azure in NwParams.|
|Deployed|Kubernetes NetworkPolicy|Pod-level network segmentation|Azure Network Policy|Configured using NetworkPolicy = azure in NwParams.|
|Deployed|Private Kubernetes API endpoint pattern|Private control plane access|AKS private cluster|Configured using EnableApiServerAccessPrivateCluster = true.|
|Disabled|Public Kubernetes API endpoint|Public API server DNS name|AKS public FQDN|Disabled using EnableApiServerAccessPrivateClusterPublicFqdn = false.|
|Existing / linked|ExternalDNS / private DNS integration pattern|Resolves private AKS API endpoint|Azure Private DNS Zone|DNS zone name set as privatelink.<region>.azmk8s.io and retrieved using Get-AzPrivateDnsZone.|
|Deployed|ExternalDNS / DNS zone link pattern|Links AKS VNet to private DNS zone|Azure Private DNS VNet Link|Created using New-AzPrivateDnsVirtualNetworkLink with VirtualNetworkId = Vnet.Id.|
|Deployed|DNS forwarding / resolver pattern|Allows resolver-side DNS resolution|Azure Private DNS VNet Link|DNS resolver VNet retrieved using Get-AzVirtualNetwork and linked using New-AzPrivateDnsVirtualNetworkLink.|
|Deployed|N/A - Azure networking resource|Connects AKS VNet to hub network|Azure Virtual WAN / Virtual Hub|Created using New-AzVirtualHubVnetConnection with RemoteVirtualNetworkId = Vnet.Id.|
|Deployed|N/A - Azure networking resource|Controls subnet routing|Azure Route Table|Created using New-AzRouteTable with Route = Route.|
|Deployed|Egress gateway pattern|Forces outbound traffic through firewall|UDR to Azure Firewall|Route created using New-AzRouteConfig with AddressPrefix 0.0.0.0/0 and NextHopType VirtualAppliance.|
|Existing / referenced|Egress gateway / firewall appliance|Central egress and security inspection|Azure Firewall in hub|Existing firewall retrieved using Get-AzFirewall; private IP used as NextHopIpAddress.|
|Deployed|Kubernetes egress routing model|AKS outbound routing behavior|User Defined Routing|Configured using OutboundType = UserDefinedRouting.|
|Not deployed|NGINX Ingress / Traefik / HAProxy Ingress|HTTP/S routing into the cluster|AGIC, Application Gateway for Containers, or NGINX|No ingress add-on, Helm chart, Application Gateway, or app-routing configuration appears in the script.|
|Not explicitly deployed|Kubernetes Service type LoadBalancer|Private service exposure|Azure Internal Load Balancer|No Kubernetes Service manifest or internal load balancer annotation appears in the script.|
|Not deployed|External global ingress / CDN edge pattern|Global edge routing, WAF, and acceleration|Azure Front Door|No Azure Front Door resource creation appears in the script.|
|Not deployed|NGINX WAF / Envoy Gateway / Gateway API|Regional L7 ingress and WAF|Application Gateway / Application Gateway for Containers|No Application Gateway or Application Gateway for Containers resource creation appears in the script.|

\---

## 4\. Cluster Configuration Components

|Status in Your Script|OSS Component|Purpose|Azure / AKS Equivalent|Notes|
|-|-|-|-|-|
|Deployed|Kubernetes|Managed Kubernetes service|Azure Kubernetes Service|Created using New-AzAksCluster.|
|Deployed|Kubernetes version|Controls Kubernetes API and node version|AKS Kubernetes version|Configured using KubernetesVersion = 1.32.3.|
|Deployed|N/A - AKS-managed resource group|Resource group for AKS-managed node resources|AKS node resource group|Configured using NodeResourceGroup = rg-...-aks-...|
|Deployed|Kubernetes node count|Initial node pool size|AKS node pool count|Configured using NodeCount = 1.|
|Deployed|Kubernetes worker node|VM SKU for system node pool|AKS node VM size|Configured using NodeVmSize = Standard\_D2as\_v5.|
|Deployed|Kubernetes node pool|Defines pool as system or user|AKS system/user node pool mode|Configured using NodePoolMode = System.|
|Deployed|Rolling upgrade surge pattern|Controls upgrade surge capacity|AKS node surge setting|Configured using NodeMaxSurge = 3.|
|Deployed|Kubernetes RBAC|Enables Kubernetes authorization|Kubernetes RBAC on AKS|Enabled using EnableRBAC = true.|
|Deployed|OIDC / external identity provider integration|Integrates AKS authentication with Entra ID|Managed Microsoft Entra integration|Configured using AadProfile with managed = true.|
|Deployed|Kubernetes RBAC external authorization pattern|Uses Azure role assignments for Kubernetes authorization|Azure RBAC for Kubernetes Authorization|Configured using enableAzureRBAC = true in AadProfile.|
|Deployed|Kubernetes admin group mapping|Grants AKS admin access to a group|Entra security-enabled admin group|Admin group object ID passed using adminGroupObjectIDs in AadProfile.|
|Enabled|OIDC issuer|Required for workload identity federation|AKS OIDC issuer|Enabled using EnableOIDCIssuer = true.|
|Partially configured|Kubernetes ServiceAccount + OIDC federation|Pod-to-Azure identity federation|Microsoft Entra Workload ID|OIDC issuer is enabled, but no federated identity credential or Kubernetes ServiceAccount mapping is shown.|
|Deployed|Cloud identity pattern|Cluster identity model|Azure Managed Identity|Configured using EnableManagedIdentity and AssignIdentity = Id.Id.|
|Not deployed|Kubernetes user node pool|Isolates app workloads from system workloads|AKS user node pool|No additional New-AzAksNodePool or user node pool configuration appears in the script.|
|Not deployed|Kubernetes Cluster Autoscaler|Automatically scales node count|AKS Cluster Autoscaler|No EnableAutoScaling, MinCount, or MaxCount node pool settings appear in the script.|
|Not configured|Multi-zone node placement pattern|Zone-resilient node placement|AKS availability zones|No AvailabilityZone or zone-related node pool setting appears in the script.|
|Deployed|Private Kubernetes API endpoint pattern|Private API server|AKS private cluster|Configured using EnableApiServerAccessPrivateCluster = true.|
|Disabled|Public Kubernetes API endpoint|Public control plane access|AKS public API endpoint / public FQDN|Disabled using EnableApiServerAccessPrivateClusterPublicFqdn = false.|

\---

## 5\. Governance, Security, and Compliance

|Status in Your Script|OSS Component|Purpose|Azure-Native Equivalent|Notes|
|-|-|-|-|-|
|Enabled|OPA Gatekeeper|Kubernetes policy enforcement|Azure Policy for AKS|Enabled through Addon includes AzurePolicy.|
|Enabled|Kubernetes RBAC / external authorization|Centralized Kubernetes authorization|Microsoft Entra ID + Azure RBAC|Enabled using enableAzureRBAC = true in AadProfile.|
|Enabled|Kubernetes RBAC|Native Kubernetes authorization|Kubernetes RBAC|Enabled using EnableRBAC = true.|
|Deployed|Kubernetes admin group mapping|Controlled administrator access|Entra security-enabled group|Group created or retrieved using Exchange/Entra commands and passed through adminGroupObjectIDs.|
|Partially configured|Vault policies / secret access policies|Controls access to secrets|Azure RBAC for Key Vault|Key Vault created with EnableRbacAuthorization; role assignment block includes Key Vault Secrets User.|
|Enabled|Private Kubernetes API endpoint pattern|Reduces public exposure|AKS private cluster|Private cluster enabled using EnableApiServerAccessPrivateCluster = true and public FQDN disabled.|
|Enabled|Egress gateway / firewall appliance|Central outbound inspection|Azure Firewall + UDR|UDR created using New-AzRouteConfig with NextHopType VirtualAppliance and Azure Firewall private IP.|
|Not deployed|Falco|Runtime threat detection and posture management|Microsoft Defender for Containers|Only listed as a TODO comment: Enable Defender for containers.|
|Not deployed|Trivy / Clair / Snyk|Container image risk detection|Defender for Cloud / ACR vulnerability assessment|Only listed as TODO-style notes around Defender and registry access; no Defender enablement command appears.|
|Not explicitly configured|Pod Security Admission / Pod Security Standards|Pod security baseline and restricted controls|Kubernetes PSA + Azure Policy|No pod security policy assignment or Azure Policy initiative assignment is shown.|
|Not fully configured|OPA Gatekeeper constraints / Kyverno policies|Standardized Kubernetes guardrails|Azure Policy initiative for Kubernetes|Comment notes baseline standard Azure Policy still needs to be added.|
|Not deployed|Policy-as-code / admission safeguards|AKS deployment risk controls|AKS deployment safeguards|Listed as a TODO comment: Deployment safeguards for AKS.|

\---

## 6\. Observability, Monitoring, and Alerting

|Status in Your Script|OSS Component|Purpose|Azure-Native Equivalent|Notes|
|-|-|-|-|-|
|Enabled|Fluent Bit / Fluentd / Metrics Server pattern|Cluster and container monitoring|Azure Monitor Container Insights|Enabled through Addon includes Monitoring.|
|Integrated|ELK / OpenSearch / Loki|Central logs and queries|Log Analytics Workspace|Workspace retrieved using Get-AzOperationalInsightsWorkspace and passed through WorkspaceResourceId.|
|Deployed|Prometheus alert rules / Alertmanager|CPU and memory alerting|Azure Monitor Metric Alerts|Created using New-AzMetricAlertRuleV2Criteria and Add-AzMetricAlertRuleV2.|
|Deployed|Alertmanager receiver|Alert notification routing|Azure Monitor Action Group|Created using New-AzActionGroupEmailReceiverObject and New-AzActionGroup.|
|Not deployed|Prometheus|Kubernetes-native metrics scraping|Azure Monitor managed service for Prometheus|No managed Prometheus resource, data collection rule, or Azure Monitor workspace configuration appears.|
|Not deployed|Grafana|Dashboards and visualization|Azure Managed Grafana|No Azure Managed Grafana resource creation appears in the script.|
|Not deployed|Jaeger / Zipkin / OpenTelemetry|Distributed tracing|Application Insights / Azure Monitor OpenTelemetry|No Application Insights, OpenTelemetry, or tracing setup appears in the script.|
|Not deployed|Loki ruler / Elasticsearch watcher / KQL alert equivalent|KQL-based alerting|Azure Monitor scheduled query alerts|No scheduled query alert rules are shown; only metric alerts are configured.|
|Not shown|Kubernetes audit log export|Platform log routing|Azure Monitor diagnostic settings|No New-AzDiagnosticSetting or AKS control plane diagnostic setting appears in the script.|

\---

## 7\. Secrets, Certificates, and Workload Identity

|Status in Your Script|OSS Component|Purpose|Azure-Native Equivalent|Notes|
|-|-|-|-|-|
|Deployed|HashiCorp Vault / external secret store|Central secret, certificate, and key store|Azure Key Vault|Created using New-AzKeyVault with Sku Premium and EnableRbacAuthorization.|
|Enabled|Secrets Store CSI Driver|Mount Key Vault objects into pods|Azure Key Vault CSI Driver|Enabled through Addon includes azure-keyvault-secrets-provider.|
|Not deployed|SecretProviderClass|Maps external secrets to pod volumes|Kubernetes SecretProviderClass CRD|No SecretProviderClass manifest appears in the script.|
|Not configured|Kubernetes Secrets|Optionally sync mounted objects to Kubernetes Secrets|CSI driver sync capability|No SecretProviderClass secretObjects configuration appears in the script.|
|Available|cert-manager / Vault PKI|Stores TLS certificates|Azure Key Vault Certificates|Key Vault exists, but no certificate import, certificate policy, or cert-manager configuration appears.|
|Partially configured|Kubernetes ServiceAccount + OIDC federation|Pod identity for accessing Azure resources|Microsoft Entra Workload ID|EnableOIDCIssuer = true is present, but no federated identity credential or annotated service account is shown.|
|Modified manually|Kubelet identity pattern|Identity used by nodes for image pulls and related operations|AKS kubelet managed identity|VMSS identity modified manually using Get-AzVmss, clearing UserAssignedIdentities, adding Id.Id, and Update-AzVmss.|
|Patched manually|Controller identity / add-on identity pattern|Identities for AKS add-ons|AKS-created add-on identities or custom UAMI|Add-on identity patch built in patch object and applied using Invoke-AzRestMethod PATCH for azurepolicy and omsagent.|

\---

## 8\. Application Delivery and Deployment Tooling

|Status in Your Script|OSS Component|Purpose|Azure-Native Equivalent / Option|Notes|
|-|-|-|-|-|
|Not deployed|Helm|Kubernetes package manager|Helm with ACR OCI support|No helm command, Helm chart deployment, or Flux HelmRelease appears in the script.|
|Not deployed|Kustomize|Manifest overlays and customization|Kustomize / Flux Kustomizations|No kustomize command or Kustomization resource appears in the script.|
|Not deployed|Flux|GitOps reconciliation|Flux v2 AKS extension|No Flux extension, az k8s-extension, or GitOps configuration appears in the script.|
|Not deployed|Argo CD|GitOps deployment UI and workflow|Bring your own Argo CD or use Flux|No Argo CD namespace, manifest, or Helm deployment appears in the script.|
|Not shown|Jenkins / Tekton / GitLab CI|CI/CD automation|Azure DevOps Pipelines|No pipeline configuration is part of this script.|
|Not shown|Jenkins / Tekton / GitLab CI|CI/CD automation|GitHub Actions|No GitHub Actions workflow is part of this script.|
|Not deployed|BuildKit / Kaniko|Container image build automation|Azure Container Registry Tasks|No ACR Task creation command appears in the script.|
|Deployed|Docker Registry / Harbor|Image registry|Azure Container Registry|Created using New-AzContainerRegistry and attached using AcrNameToAttach.|

\---

## 9\. Service Mesh, Ingress, and Application Exposure

|Status in Your Script|OSS Component|Purpose|Azure-Native Equivalent|Notes|
|-|-|-|-|-|
|Not deployed|Istio|Service mesh, mTLS, traffic splitting, retries, and telemetry|AKS Istio add-on|No Istio add-on, mesh profile, istioctl, or Helm installation appears in the script.|
|Not deployed|Linkerd|Lightweight service mesh|Bring your own Linkerd|No Linkerd CLI, Helm chart, or manifest deployment appears in the script.|
|Not deployed|NGINX Ingress Controller|HTTP/S ingress into cluster|AKS app routing add-on or BYO NGINX|No NGINX ingress add-on, Helm chart, or ingress controller manifest appears.|
|Not deployed|Application Gateway Ingress Controller|Uses Application Gateway as AKS ingress|Application Gateway Ingress Controller|No AGIC add-on or Application Gateway resource appears in the script.|
|Not deployed|Gateway API / Envoy Gateway|Modern L7 ingress pattern|Application Gateway for Containers|No Gateway API, Envoy Gateway, or Application Gateway for Containers configuration appears.|
|Not deployed|External global ingress / CDN edge pattern|Global routing, WAF, and edge acceleration|Azure Front Door|No Front Door resource creation appears in the script.|
|Not deployed|Kong / Ambassador / APISIX|API publishing, security, throttling, and subscriptions|Azure API Management|No API Management resource creation appears in the script.|

\---

## 10\. Autoscaling and Resiliency

|Status in Your Script|OSS Component|Purpose|Azure-Native Equivalent|Notes|
|-|-|-|-|-|
|Not explicitly configured|Horizontal Pod Autoscaler|Scales pods based on CPU, memory, or custom metrics|Kubernetes HPA on AKS|No HPA manifest appears; HPA is configured per workload after cluster creation.|
|Not deployed|Kubernetes Cluster Autoscaler|Scales node count|AKS Cluster Autoscaler|No EnableAutoScaling, MinCount, or MaxCount settings appear in ComputeParams.|
|Not deployed|KEDA|Event-driven autoscaling|AKS KEDA add-on|KEDA is not included in the Addon array.|
|Not deployed|Kubernetes node pools|Workload isolation and scaling|AKS system and user node pools|Only the initial system node pool is configured through NodePoolMode = System.|
|Not configured|Multi-zone node placement pattern|Node resilience across zones|AKS zone-aware node pools|No availability zone setting appears in the node pool configuration.|
|Not configured|Pod Disruption Budget|Protect app availability during voluntary disruptions|Kubernetes PDB|No PDB manifest appears in the script.|
|Not deployed|Velero|Cluster and application backup|Azure Backup for AKS / Velero|No Azure Backup, backup extension, or Velero deployment appears in the script.|

\---

## 11\. Storage and Data Services

|Status in Your Script|OSS Component|Purpose|Azure-Native Equivalent|Notes|
|-|-|-|-|-|
|Available through AKS, not explicitly configured|Kubernetes PV / PVC|Persistent application storage|Azure Disk CSI / Azure Files CSI|No PVC manifests appear; AKS can provision storage later when workloads request it.|
|Not deployed|NFS provisioner / RWX storage|Multi-pod shared file access|Azure Files / Azure NetApp Files|No Azure Files share, Azure NetApp Files volume, or NFS provisioner appears in the script.|
|Not deployed|MinIO / S3-compatible object store|Blob or object data|Azure Blob Storage|No storage account or Blob container creation appears in the script.|
|Not deployed|PostgreSQL / MySQL / SQL Server in-cluster|Relational data|Azure SQL / Azure Database for PostgreSQL / Azure Database for MySQL|No database service creation appears in the script.|
|Not deployed|Redis in-cluster|Distributed cache|Azure Cache for Redis|No Redis cache creation appears in the script.|
|Not deployed|Velero / storage snapshots|Backup of cluster resources and persistent volumes|Azure Backup for AKS|No backup vault, backup policy, or AKS backup extension appears in the script.|

\---

## 12\. External Services Commonly Paired with AKS

|Status in Your Script|Need|OSS Component|Azure-Native External Service|Notes|
|-|-|-|-|-|
|Deployed|Container images|Docker Hub / Harbor|Azure Container Registry|Created using New-AzContainerRegistry and attached with AcrNameToAttach.|
|Deployed|Secrets|Kubernetes Secrets / HashiCorp Vault|Azure Key Vault|Created using New-AzKeyVault and integrated through azure-keyvault-secrets-provider add-on.|
|Integrated|Logs|ELK / OpenSearch / Fluentd / Fluent Bit|Log Analytics Workspace|Existing workspace retrieved using Get-AzOperationalInsightsWorkspace and passed as WorkspaceResourceId.|
|Not deployed|Metrics|Prometheus|Azure Monitor managed Prometheus|No managed Prometheus configuration appears in the script.|
|Not deployed|Dashboards|Grafana|Azure Managed Grafana|No Managed Grafana resource appears in the script.|
|Not deployed|Messaging|RabbitMQ / NATS|Azure Service Bus|No Service Bus namespace, queue, or topic creation appears in the script.|
|Not deployed|Event streaming|Kafka|Azure Event Hubs|No Event Hubs namespace or event hub creation appears in the script.|
|Not deployed|Event routing|In-cluster event bus|Azure Event Grid|No Event Grid topic or subscription creation appears in the script.|
|Not deployed|Database|PostgreSQL / MySQL in cluster|Azure Database for PostgreSQL / Azure Database for MySQL|No managed database resource creation appears in the script.|
|Not deployed|Cache|Redis in cluster|Azure Cache for Redis|No Azure Cache for Redis resource creation appears in the script.|
|Not deployed|API Gateway|Kong / Ambassador / APISIX|Azure API Management|No API Management resource creation appears in the script.|
|Not deployed|Global ingress|In-cluster global ingress|Azure Front Door|No Azure Front Door resource creation appears in the script.|
|Not deployed|WAF ingress|NGINX + ModSecurity|Application Gateway WAF / Front Door WAF|No Application Gateway WAF or Front Door WAF configuration appears in the script.|

\---

## 13\. Summary Coverage Matrix

|Status in Your Script|Area|OSS Component|Azure-Native Equivalent|Notes|
|-|-|-|-|-|
|Covered|Mandatory Kubernetes control plane|kube-apiserver, etcd, kube-scheduler, kube-controller-manager|AKS-managed control plane|Covered by New-AzAksCluster.|
|Covered|Private AKS API|Private Kubernetes API endpoint pattern|AKS private cluster|Configured using EnableApiServerAccessPrivateCluster = true.|
|Strong coverage|Azure networking|CNI, NetworkPolicy, egress gateway pattern, private DNS integration|Azure CNI, UDR, Azure Firewall, Private DNS, vHub|Covered by NetworkPlugin = azure, NetworkPolicy = azure, New-AzRouteConfig, New-AzPrivateDnsVirtualNetworkLink, and New-AzVirtualHubVnetConnection.|
|Good foundation|Identity|Kubernetes RBAC, OIDC, ServiceAccount federation|UAMI, Entra integration, Azure RBAC, OIDC issuer|Covered by New-AzUserAssignedIdentity, AssignIdentity, AadProfile, EnableRBAC, and EnableOIDCIssuer.|
|Covered|Registry|Docker Registry / Harbor|Azure Container Registry|Covered by New-AzContainerRegistry and AcrNameToAttach.|
|Partially covered|Secrets platform|Secrets Store CSI Driver / Vault|Azure Key Vault + Key Vault CSI Driver|Covered by New-AzKeyVault and azure-keyvault-secrets-provider, but no SecretProviderClass is deployed.|
|Partially covered|Monitoring|Fluent Bit / Metrics Server / Prometheus-style monitoring|Container Insights / Log Analytics|Covered by Monitoring add-on and WorkspaceResourceId; managed Prometheus and Grafana are not configured.|
|Partially covered|Governance|OPA Gatekeeper / Kyverno|Azure Policy for AKS|AzurePolicy add-on enabled, but no policy initiative assignment is shown.|
|Not covered|Ingress|NGINX Ingress / Traefik / Gateway API|AGIC, Application Gateway for Containers, or NGINX|No ingress controller or Application Gateway configuration appears.|
|Not covered|GitOps|Flux / Argo CD|Flux v2 AKS extension|No Flux or Argo CD deployment appears.|
|Partially covered|Autoscaling|HPA / Cluster Autoscaler / KEDA|HPA, AKS Cluster Autoscaler, AKS KEDA add-on|NodeCount is fixed at 1; no autoscaler or KEDA add-on appears.|
|Not covered|Service mesh|Istio / Linkerd|AKS Istio add-on|No Istio or Linkerd configuration appears.|
|Not covered|Defender / security posture|Falco / Trivy|Microsoft Defender for Containers|Defender is mentioned only as a TODO comment.|
|Not covered|Backup / DR|Velero|Azure Backup for AKS / Velero|No backup configuration appears.|

\---

## 14\. Recommended Next-Step Order for This Script

|Priority|Status in Your Script|Add / Improve|OSS Component|Azure-Native Equivalent|Notes|
|-|-|-|-|-|-|
|1|Needs review|Increase subnet planning / validate IP capacity|CNI IP planning|Azure CNI subnet sizing|Current subnet is 172.25.22.0/26; review before scaling nodes or pods.|
|2|Not deployed|Add separate user node pool|Kubernetes node pools|AKS user node pool|Current script configures only NodePoolMode = System.|
|3|Not deployed|Enable cluster autoscaler|Kubernetes Cluster Autoscaler|AKS Cluster Autoscaler|Add autoscaler settings such as EnableAutoScaling, MinCount, and MaxCount.|
|4|Partially configured|Complete Workload Identity pattern|ServiceAccount + OIDC federation|Microsoft Entra Workload ID|OIDC is enabled using EnableOIDCIssuer, but federated identity and service account mapping are still needed.|
|5|Partially configured|Add policy initiative assignments|OPA Gatekeeper / Kyverno policies|Azure Policy initiatives for Kubernetes|AzurePolicy add-on is enabled, but baseline initiative assignment is noted as TODO.|
|6|Not deployed|Add Defender for Containers|Falco / Trivy|Microsoft Defender for Containers|Script includes a TODO comment for Defender for Containers.|
|7|Not deployed|Add ingress design|NGINX Ingress / Gateway API / Traefik|Application Gateway for Containers, AGIC, or NGINX|No ingress pattern is currently deployed.|
|8|Not deployed|Add Flux GitOps|Flux|Flux v2 AKS extension|No Flux extension or GitOps configuration is currently deployed.|
|9|Not deployed|Add managed Prometheus and Grafana|Prometheus / Grafana|Azure Monitor managed Prometheus + Azure Managed Grafana|Monitoring add-on exists, but Prometheus and Grafana are not configured.|
|10|Not deployed|Add Istio only if required|Istio|AKS Istio add-on|No service mesh is currently deployed; add only if requirements justify it.|



