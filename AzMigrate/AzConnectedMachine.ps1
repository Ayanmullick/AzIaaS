#Azure Arc

Get-AzConnectedMachine -ResourceGroupName 'rg-<>-d-c-01' -Name '<>'
<#
AdFqdn                                      : <>.local
AgentConfigurationConfigMode                : full
AgentConfigurationExtensionsAllowList       : {}
AgentConfigurationExtensionsBlockList       : {}
AgentConfigurationExtensionsEnabled         : true
AgentConfigurationGuestConfigurationEnabled : true
AgentConfigurationIncomingConnectionsPort   : {}
AgentConfigurationProxyBypass               : {}
AgentConfigurationProxyUrl                  :
AgentUpgradeCorrelationId                   :
AgentUpgradeDesiredVersion                  :
AgentUpgradeEnableAutomaticUpgrade          : False
AgentUpgradeLastAttemptDesiredVersion       :
AgentUpgradeLastAttemptMessage              :
AgentUpgradeLastAttemptStatus               :
AgentUpgradeLastAttemptTimestamp            :
AgentVersion                                : 1.53.03070.2299
ClientPublicKey                             : <>
CloudMetadataProvider                       : N/A
DetectedProperty                            : {
                                                "architecture": "amd64",
                                                "cloudprovider": "N/A",
                                                "coreCount": "2",
                                                "logicalCoreCount": "2",
                                                "manufacturer": "VMware, Inc.",
                                                "model": "VMware Virtual Platform",
                                                "mssqldiscovered": "false",
                                                "mysqldiscovered": "false",
                                                "pgsqldiscovered": "false",
                                                "processorCount": "2",
                                                "processorNames": "Intel(R) Xeon(R) Gold 6346 CPU @ 3.10GHz",
                                                "productType": "8",
                                                "serialNumber": "None",
                                                "smbiosAssetTag": "No Asset Tag",
                                                "totalPhysicalMemoryInBytes": "8589934592",
                                                "totalPhysicalMemoryInGigabytes": "8",
                                                "vmuuidEsu2012": "FB451042-C6DF-0A7E-4C65-9BD2B9EB34D2"
                                              }
DisplayName                                 : <>
DnsFqdn                                     : <>.local
DomainName                                  : <>local
ErrorDetail                                 : {}
Extension                                   :
ExtensionServiceStartupType                 : automatic
ExtensionServiceStatus                      : running
FirmwareProfileSerialNumber                 : None
FirmwareProfileType                         : BIOS
Fqdn                                        : <>
GuestConfigurationServiceStartupType        : automatic
GuestConfigurationServiceStatus             : running
HardwareProfileNumberOfCpuSocket            : 2
HardwareProfileProcessor                    : {{
                                                "name": "Intel(R) Xeon(R) Gold 6346 CPU @ 3.10GHz",
                                                "numberOfCores": 1
                                              }, {
                                                "name": "Intel(R) Xeon(R) Gold 6346 CPU @ 3.10GHz",
                                                "numberOfCores": 1
                                              }}
HardwareProfileTotalPhysicalMemoryInByte    : 8589934592
Id                                          : /subscriptions/<>/resourceGroups/rg-<>-d-c-01/providers/Microsoft.HybridCompute/machines/<>
IdentityPrincipalId                         : <>
IdentityTenantId                            : <>
IdentityType                                : SystemAssigned
Kind                                        :
LastStatusChange                            : Wed 8.6.25 7:13:31 PM
LicenseProfile                              : {
                                                "softwareAssurance": {
                                                  "softwareAssuranceCustomer": true
                                                },
                                                "esuProfile": {
                                                  "esuKeys": [
                                                    {
                                                      "sku": "Server-ESU-Year1",
                                                      "licenseStatus": 0
                                                    },
                                                    {
                                                      "sku": "Server-ESU-Year2",
                                                      "licenseStatus": 0
                                                    },
                                                    {
                                                      "sku": "Server-ESU-Year3",
                                                      "licenseStatus": 0
                                                    }
                                                  ],
                                                  "serverType": "Datacenter",
                                                  "esuEligibility": "Eligible",
                                                  "esuKeyState": "Inactive",
                                                  "licenseAssignmentState": "NotAssigned"
                                                },
                                                "licenseStatus": "Licensed"
                                              }
Location                                    : centralus
LocationDataCity                            :
LocationDataCountryOrRegion                 :
LocationDataDistrict                        :
LocationDataName                            :
MssqlDiscovered                             : false
Name                                        : <>
NetworkProfileNetworkInterface              : {{
                                                "macAddress": "00:50:56:90:36:9c",
                                                "id": "12",
                                                "name": "Ethernet0",
                                                "ipAddresses": [
                                                  {
                                                    "subnet": {
                                                      "addressPrefix": "10.31.202.0/28"
                                                    },
                                                    "address": "10.31.202.7",
                                                    "ipAddressVersion": "IPv4"
                                                  }
                                                ]
                                              }}
OSEdition                                   : serverdatacenter
OSName                                      : windows
OSProfile                                   : {
                                                "windowsConfiguration": {
                                                  "patchSettings": {
                                                    "assessmentMode": "AutomaticByPlatform"
                                                  }
                                                },
                                                "computerName": "<>"
                                              }
OSSku                                       : Windows Server 2012 Datacenter
OSType                                      : windows
OSVersion                                   : 6.2.9200.24710
ParentClusterResourceId                     :
PrivateLinkScopeResourceId                  :
ProvisioningState                           : Succeeded
Resource                                    : {{
                                                "id":
                                              "/subscriptions/<>/resourceGroups/rg-<>-d-c-01/providers/Microsoft.HybridCompute/machines/<>/extensions/AzureMonitorWindowsAgent",
                                                "name": "AzureMonitorWindowsAgent",
                                                "type": "Microsoft.HybridCompute/machines/extensions",
                                                "location": "centralus",
                                                "properties": {
                                                  "instanceView": {
                                                    "status": {
                                                      "code": "0",
                                                      "level": "Information",
                                                      "message": "Extension Message: ExtensionOperation:enable. Status:Success"
                                                    },
                                                    "name": "AzureMonitorWindowsAgent",
                                                    "type": "AzureMonitorWindowsAgent",
                                                    "typeHandlerVersion": "1.34.0.0"
                                                  },
                                                  "publisher": "Microsoft.Azure.Monitor",
                                                  "type": "AzureMonitorWindowsAgent",
                                                  "typeHandlerVersion": "1.34.0.0",
                                                  "enableAutomaticUpgrade": true,
                                                  "autoUpgradeMinorVersion": false,
                                                  "provisioningState": "Succeeded"
                                                }
                                              }, {
                                                "id": "/subscriptions/<>/resourceGroups/rg-<>-d-c-01/providers/Microsoft.HybridCompute/machines/<>/extensions/MDE.Windows",
                                                "name": "MDE.Windows",
                                                "type": "Microsoft.HybridCompute/machines/extensions",
                                                "tags": {
                                                  "AppName": "OnPremResources",
                                                  "Division": "Enterprise"
                                                },
                                                "location": "centralus",
                                                "properties": {
                                                  "instanceView": {
                                                    "status": {
                                                      "code": "51",
                                                      "level": "Error",
                                                      "message": "Extension Message: Failed to configure Microsoft Defender for Endpoint: Onboarding to MDE via Microsoft Defender for Cloud for this operating system is not supported.
                                              Read more about supported operating systems: https://docs.microsoft.com/en-us/azure/defender-for-cloud/integration-defender-for-endpoint, executionlog: [2025-06-30 19:44:12Z][Information]
                                              Attempting to read Arc proxy settings\r\n[2025-06-30 19:44:12Z][Information] Arc proxy was not set. No custom proxy will be used\r\n[2025-06-30 19:44:12Z][Information] Path
                                              HKLM:\\Software\\Policies\\Microsoft\\Windows Advanced Threat Protection already exists\r\n[2025-06-30 19:44:12Z][Information] Path
                                              HKLM:\\Software\\Policies\\Microsoft\\Windows\\DataCollection already exists\r\n[2025-06-30 19:44:12Z][Information] Proxy URI is empty -\u003e disable proxy\r\n[2025-06-30
                                              19:44:13Z][Information] Try to get MDE onboarding package applicability\r\n[2025-06-30 19:44:13Z][Information] MDE onboarding package applicability: 0\r\n[2025-06-30 19:44:13Z][Error]
                                              Onboarding to MDE via Microsoft Defender for Cloud for this operating system is not supported. Read more about supported operating systems:
                                              https://docs.microsoft.com/en-us/azure/defender-for-cloud/integration-defender-for-endpoint \r\n[2025-06-30 19:44:13Z][Error] Failed to configure Microsoft Defender for Endpoint: Onboarding
                                              to MDE via Microsoft Defender for Cloud for this operating system is not supported. Read more about supported operating systems:
                                              https://docs.microsoft.com/en-us/azure/defender-for-cloud/integration-defender-for-endpoint\r\n[2025-06-30 19:44:14Z][Information] Set handler status
                                              (C:\\Packages\\Plugins\\Microsoft.Azure.AzureDefenderForServers.MDE.Windows\\1.0.11.2\\status\\0.status), Status=error, Code=51, Message=\u0027Failed to configure Microsoft Defender for
                                              Endpoint: Onboarding to MDE via Microsoft Defender for Cloud for this operating system is not supported. Read more about supported operating systems:
                                              https://docs.microsoft.com/en-us/azure/defender-for-cloud/integration-defender-for-endpoint\u0027\nExtension Error:
                                              \nC:\\Packages\\Plugins\\Microsoft.Azure.AzureDefenderForServers.MDE.Windows\\1.0.11.2\u003ePowershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass
                                              C:\\Packages\\Plugins\\Microsoft.Azure.AzureDefenderForServers.MDE.Windows\\1.0.11.2\\\\MdeExtensionHandlerWrapper.ps1 -Action enable \nVERBOSE: [2025-06-30 19:41:19Z][Information] Start
                                              executing handler action: \nenable\nVERBOSE: [2025-06-30 19:41:22Z][Information] Set handler status
                                              \n(C:\\Packages\\Plugins\\Microsoft.Azure.AzureDefenderForServers.MDE.Windows\\1.0.11\n.2\\status\\0.status), Status=transitioning, Code=1, Message=\u0027Configuration In
                                              \nProgress\u0027\nVERBOSE: [2025-06-30 19:41:22Z][Information] Invoking MdeExtensionHandler.ps1 \nin background process in order to install/configuration/onboard MDE\nVERBOSE: [2025-06-30
                                              19:41:23Z][Information] End executing handler action: \nenable with exit code: 0\n\nC:\\Packages\\Plugins\\Microsoft.Azure.AzureDefenderForServers.MDE.Windows\\1.0.11.2\u003ePowershell.exe
                                              -NoProfile -NonInteractive -ExecutionPolicy Bypass C:\\Packages\\Plugins\\Microsoft.Azure.AzureDefenderForServers.MDE.Windows\\1.0.11.2\\\\MdeExtensionHandlerWrapper.ps1 -Action enable
                                              \nVERBOSE: [2025-06-30 19:43:50Z][Information] Start executing handler action: \nenable\nVERBOSE: [2025-06-30 19:43:53Z][Information] Set handler status
                                              \n(C:\\Packages\\Plugins\\Microsoft.Azure.AzureDefenderForServers.MDE.Windows\\1.0.11\n.2\\status\\0.status), Status=transitioning, Code=1, Message=\u0027Configuration In
                                              \nProgress\u0027\nVERBOSE: [2025-06-30 19:43:53Z][Information] Invoking MdeExtensionHandler.ps1 \nin background process in order to install/configuration/onboard MDE\nVERBOSE: [2025-06-30
                                              19:43:54Z][Information] End executing handler action: \nenable with exit code: 0\n\nC:\\Packages\\Plugins\\Microsoft.Azure.AzureDefenderForServers.MDE.Windows\\1.0.11.2\u003ePowershell.exe
                                              -NoProfile -NonInteractive -ExecutionPolicy Bypass C:\\Packages\\Plugins\\Microsoft.Azure.AzureDefenderForServers.MDE.Windows\\1.0.11.2\\\\MdeExtensionHandlerWrapper.ps1 -Action install
                                              \nVERBOSE: [2024-11-25 17:03:12Z][Information] Start executing handler action: \ninstall\nVERBOSE: [2024-11-25 17:03:12Z][Information] MDE \ninstallation/configuration/onboarding occurs /
                                              will occur in \u0027enable\u0027\nVERBOSE: [2024-11-25 17:03:12Z][Information] End executing handler action: \ninstall with exit code:
                                              0\n\nC:\\Packages\\Plugins\\Microsoft.Azure.AzureDefenderForServers.MDE.Windows\\1.0.11.2\u003ePowershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass
                                              C:\\Packages\\Plugins\\Microsoft.Azure.AzureDefenderForServers.MDE.Windows\\1.0.11.2\\\\MdeExtensionHandlerWrapper.ps1 -Action enable \nVERBOSE: [2024-11-25 17:03:17Z][Information] Start
                                              executing handler action: \nenable\nVERBOSE: [2024-11-25 17:03:19Z][Information] Set handler status
                                              \n(C:\\Packages\\Plugins\\Microsoft.Azure.AzureDefenderForServers.MDE.Windows\\1.0.11\n.2\\status\\0.status), Status=transitioning, Code=1, Message=\u0027Configuration In
                                              \nProgress\u0027\nVERBOSE: [2024-11-25 17:03:19Z][Information] Invoking MdeExtensionHandler.ps1 \nin background process in order to install/configuration/onboard MDE\nVERBOSE: [2024-11-25
                                              17:03:20Z][Information] End executing handler action: \nenable with exit code: 0\n"
                                                    },
                                                    "name": "MDE.Windows",
                                                    "type": "MDE.Windows",
                                                    "typeHandlerVersion": "1.0.11.2"
                                                  },
                                                  "publisher": "Microsoft.Azure.AzureDefenderForServers",
                                                  "type": "MDE.Windows",
                                                  "typeHandlerVersion": "1.0.11.2",
                                                  "enableAutomaticUpgrade": true,
                                                  "autoUpgradeMinorVersion": false,
                                                  "settings": {
                                                    "azureResourceId": "/subscriptions/<>/resourceGroups/rg-<>-d-c-01/providers/Microsoft.HybridCompute/machines/<>",
                                                    "forceReOnboarding": true,
                                                    "vNextEnabled": true,
                                                    "autoUpdate": true
                                                  },
                                                  "provisioningState": "Failed"
                                                }
                                              }, {
                                                "id":
                                              "/subscriptions/<>/resourceGroups/rg-<>-d-c-01/providers/Microsoft.HybridCompute/machines/<>/extensions/AzureSecurityWindowsAgent",
                                                "name": "AzureSecurityWindowsAgent",
                                                "type": "Microsoft.HybridCompute/machines/extensions",
                                                "tags": {
                                                  "AppName": "OnPremResources",
                                                  "Division": "Enterprise"
                                                },
                                                "location": "centralus",
                                                "properties": {
                                                  "instanceView": {
                                                    "status": {
                                                      "code": "0",
                                                      "level": "Information",
                                                      "message": "Extension Message: ExtensionOperation:enable. Status:Success"
                                                    },
                                                    "name": "AzureSecurityWindowsAgent",
                                                    "type": "AzureSecurityWindowsAgent",
                                                    "typeHandlerVersion": "1.8.0.76"
                                                  },
                                                  "publisher": "Microsoft.Azure.Security.Monitoring",
                                                  "type": "AzureSecurityWindowsAgent",
                                                  "typeHandlerVersion": "1.8.0.76",
                                                  "enableAutomaticUpgrade": true,
                                                  "autoUpgradeMinorVersion": false,
                                                  "provisioningState": "Succeeded"
                                                }
                                              }, {
                                                "id": "/subscriptions/<>/resourceGroups/rg-<>-d-c-01/providers/Microsoft.HybridCompute/machines/<>/extensions/DependencyAgentWindows",
                                                "name": "DependencyAgentWindows",
                                                "type": "Microsoft.HybridCompute/machines/extensions",
                                                "tags": {
                                                  "AppName": "OnPremResources",
                                                  "Division": "Enterprise"
                                                },
                                                "location": "centralus",
                                                "properties": {
                                                  "instanceView": {
                                                    "status": {
                                                      "code": "0",
                                                      "level": "Information",
                                                      "message": "Extension Message: success"
                                                    },
                                                    "name": "DependencyAgentWindows",
                                                    "type": "DependencyAgentWindows",
                                                    "typeHandlerVersion": "9.10.18.4770"
                                                  },
                                                  "publisher": "Microsoft.Azure.Monitoring.DependencyAgent",
                                                  "type": "DependencyAgentWindows",
                                                  "typeHandlerVersion": "9.10.18.4770",
                                                  "enableAutomaticUpgrade": true,
                                                  "autoUpgradeMinorVersion": false,
                                                  "settings": {
                                                    "enableAMA": "true"
                                                  },
                                                  "provisioningState": "Succeeded"
                                                }
                                              }…}
ResourceGroupName                           : rg-<>-d-c-01
Status                                      : Connected
StorageProfileDisk                          : {{
                                                "path": "\\\\.\\PHYSICALDRIVE3",
                                                "diskType": "Fixed hard disk media",
                                                "generatedId": "\\\\.\\PHYSICALDRIVE3",
                                                "id": "\\\\.\\PHYSICALDRIVE3",
                                                "name": "VMware Virtual disk SCSI Disk Device",
                                                "maxSizeInBytes": 32210196480
                                              }, {
                                                "path": "\\\\.\\PHYSICALDRIVE2",
                                                "diskType": "Fixed hard disk media",
                                                "generatedId": "\\\\.\\PHYSICALDRIVE2",
                                                "id": "\\\\.\\PHYSICALDRIVE2",
                                                "name": "VMware Virtual disk SCSI Disk Device",
                                                "maxSizeInBytes": 42944186880
                                              }, {
                                                "path": "\\\\.\\PHYSICALDRIVE1",
                                                "diskType": "Fixed hard disk media",
                                                "generatedId": "\\\\.\\PHYSICALDRIVE1",
                                                "id": "\\\\.\\PHYSICALDRIVE1",
                                                "name": "VMware Virtual disk SCSI Disk Device",
                                                "maxSizeInBytes": 21467980800
                                              }, {
                                                "path": "\\\\.\\PHYSICALDRIVE0",
                                                "diskType": "Fixed hard disk media",
                                                "generatedId": "\\\\.\\PHYSICALDRIVE0",
                                                "id": "\\\\.\\PHYSICALDRIVE0",
                                                "name": "VMware Virtual disk SCSI Disk Device",
                                                "maxSizeInBytes": 85896599040
                                              }}
SystemDataCreatedAt                         :
SystemDataCreatedBy                         :
SystemDataCreatedByType                     :
SystemDataLastModifiedAt                    :
SystemDataLastModifiedBy                    :
SystemDataLastModifiedByType                :
Tags                                        : {
                                                "AppName": "OnPremResources",
                                                "Division": "Enterprise",
                                                "PatchGroup": "1st-Tuesday-1000-1200",
                                                "InfraOwner": "Thao, Pao"
                                              }
Type                                        : Microsoft.HybridCompute/machines
VMId                                        : <>
VMUuid                                      : FB451042-C6DF-0A7E-4C65-9BD2B9EB34D2
#>