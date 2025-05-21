#region Discovery in Azure Migrate
$ResourceGroup = Get-AzResourceGroup -Name verint-gz-lab-azmigrate
$MigrateProject = Get-AzMigrateProject -ResourceGroupName verint-gz-lab-azmigrate -Name verint-gz-lab-azmigrate-eus   #Other one verint-gz-lab-azmigrate. Same RG

$DiscoveredServers = Get-AzMigrateDiscoveredServer -ProjectName $MigrateProject.Name -ResourceGroupName $ResourceGroup.ResourceGroupName


Get-AzMigrateDiscoveredServer -ProjectName $MigrateProject.Name -ResourceGroupName $ResourceGroup.ResourceGroupName


$DiscoveredServers|
    select DisplayName,VMFqdn,Firmware,HostName,HostPowerState,NumberOfApplication,NumberOfProcessorCore,AllocatedMemoryInMb,OperatingSystemDetailOSName,OperatingSystemDetailOSType,VCenterFqdn -First 1|
            fl
$DiscoveredServers| Export-Excel '.\Users\AyanMullick\OneDrive - Mullick\PowerShell\Verint\DiscoveredServers.xlsx' -Verbose

$DiscoveredServers|? DisplayName -EQ 'IC-HFR10-TWILIO'| 
    select DisplayName,VMFqdn,Firmware,HostName,HostPowerState,NumberOfApplication,NumberOfProcessorCore,AllocatedMemoryInMb,OperatingSystemDetailOSName,OperatingSystemDetailOSType,VCenterFqdn|fl

Get-AzMigrateDiscoveredServer -ProjectName verint-gz-lab-azmigrate -ResourceGroupName $ResourceGroup.ResourceGroupName -ApplianceName UK-AZ-Migrate -DisplayName DP-RNRX-LIC|
select DisplayName,VMFqdn,Firmware,HostName,HostPowerState,NumberOfApplication,@{n='IP';e={$_.NetworkAdapter.IPAddressList}},@{n='IPType';e={$_.NetworkAdapter.IPAddressType}},
        NumberOfProcessorCore,AllocatedMemoryInMb,@{n='DiskGb';e={$_.Disk.MaxSizeInByte/1Gb}},OperatingSystemDetailOSName,OperatingSystemDetailOSType,VCenterFqdn|
            Format-MarkdownTableListStyle -ShowMarkdown  #Formats so it can be copied to Jira as table





$twilio|select DisplayName,Description, BiosGuid, VMFqdn,VMwareToolsStatus, Firmware,DataCenterScope,VCenterFqdn, HostName,HostPowerState,
            @{n='CreatedTime';e={([TimeZoneInfo]::ConvertTime([DateTime]::Parse($_.CreatedTimestamp), [TimeZoneInfo]::FindSystemTimeZoneById('Central Standard Time'))).ToString('MM.dd.yy-HH:mm:ss')}},
            @{n='ErrorCode';e={$_.Error[0].Code}},@{n='Severity';e={$_.Error[0].Severity}},@{n='Recommendation';e={$_.Error[0].RecommendedAction}},@{n='Apps';e={$_.NumberOfApplication}},
            @{n='IP';e={$_.NetworkAdapter|ForEach-Object { "$($_.Label):$($_.IPAddressList)| " } | Out-String -NoNewline}},@{n='IPType';e={$_.NetworkAdapter[0].IPAddressType}},
            NumberOfProcessorCore,@{n='RAMGb';e={[Math]::Ceiling($_.AllocatedMemoryInMb/1Gb)}},
            @{n='DiskGb';e={$_.Disk |ForEach-Object { "$($_.Lun):$($_.MaxSizeInByte/1Gb)| " } | Out-String -NoNewline}},
            OperatingSystemDetailOSName,OperatingSystemDetailOSType,GuestOSDetailOsname, InstanceUuid            

Get-AzMigrateDiscoveredServer -ProjectName verint-gz-lab-azmigrate-eus -ResourceGroupName $ResourceGroup.ResourceGroupName -ApplianceName ATLAZMIGRATE -DisplayName Attachments            
#endregion

#region replication
# Initialize replication infrastructure for the current Migrate project. Didn't use. Was already initialized
Initialize-AzMigrateReplicationInfrastructure -ResourceGroupName $ResourceGroup.ResourceGroupName -ProjectName $MigrateProject. Name -Scenario agentlessVMware -TargetRegion "CentralUS"        


$DiscoveredServer = Get-AzMigrateDiscoveredServer -ProjectName verint-gz-lab-azmigrate -ResourceGroupName $ResourceGroup.ResourceGroupName -DisplayName DP-RNRX-LIC #| Format-Table DisplayName, Name, Type

$TargetResourceGroup = Get-AzResourceGroup -Name GZ_Migrate_EUS            # Retrieve the resource group that you want to migrate to
$TargetVirtualNetwork = Get-AzVirtualNetwork -Name verint-lab-eus-lab-vnet  # Retrieve the Azure virtual network and subnet that you want to migrate to

# Start replication for a discovered VM in an Azure Migrate project
$MigrateJob =  New-AzMigrateServerReplication -InputObject $DiscoveredServer -TargetResourceGroupId $TargetResourceGroup.ResourceId -TargetNetworkId $TargetVirtualNetwork.Id `
    -LicenseType WindowsServer -OSDiskID $DiscoveredServer.Disk[0].Uuid -TargetSubnetName $TargetVirtualNetwork.Subnets[2].Name -DiskType Standard_LRS -TargetVMName $DiscoveredServer.DisplayName `
    -TargetVMSize ('Standard_B'+$DiscoveredServer.NumberOfProcessorCore+'ms') #-Verbose    

#For Linux    
$MigrateJob =  New-AzMigrateServerReplication -InputObject $DiscoveredServer -TargetResourceGroupId $TargetResourceGroup.ResourceId -TargetNetworkId $TargetVirtualNetwork.Id -LicenseType NoLicenseType `
        -OSDiskID $DiscoveredServer.Disk[0].Uuid -TargetSubnetName $TargetVirtualNetwork.Subnets[2].Name -DiskType Standard_LRS -TargetVMName $DiscoveredServer.DisplayName `
        -TargetVMSize ('Standard_B'+$DiscoveredServer.NumberOfProcessorCore+'ms') -Verbose


# Track job status to check for completion
while (($MigrateJob.State -eq 'InProgress') -or ($MigrateJob.State -eq 'NotStarted')){
    #If the job hasn't completed, sleep for 10 seconds before checking the job status again
    sleep 10;
    $MigrateJob = Get-AzMigrateJob -InputObject $MigrateJob
}
$MigrateJob.State  #Check if the Job completed successfully. The updated job state of a successfully completed job should be "Succeeded".
(Get-AzMigrateJob -InputObject $MigrateJob).Task
(Get-AzMigrateJob -ResourceGroupName verint-gz-lab-azmigrate -ProjectName verint-gz-lab-azmigrate-eus|? TargetObjectName -EQ 'KR-W2016-1')[0]


# List replicating VMs and filter the result for selecting a replicating VM. This cmdlet will not return all properties of the replicating VM.
$ReplicatingServer = Get-AzMigrateServerReplication -ProjectName verint-gz-lab-azmigrate -ResourceGroupName $ResourceGroup.ResourceGroupName -MachineName $DiscoveredServer.DisplayName -Verbose
Get-AzMigrateServerReplication -TargetObjectID $ReplicatingServer.Id
$replicatingserver.ProviderSpecificDetail|FL  #InitialSeedingProgressPercentage, MigrationProgressPercentage | shows progress
$Replicatingserver.ProviderSpecificDetail|FL *perc*
(Get-AzMigrateServerReplication -ProjectName verint-gz-lab-azmigrate-eus -ResourceGroupName verint-gz-lab-azmigrate -MachineName $DiscoveredServer.DisplayName).ProviderSpecificDetail|FL *perc* #Worked

(Get-AzMigrateServerReplication -ProjectName verint-gz-lab-azmigrate-eus -ResourceGroupName $ResourceGroup.ResourceGroupName -MachineName WIN10-CISCO-Clone).ProviderSpecificDetail|
     FL TargetVMName, TargetVMSize, FirmwareType, InstanceType, LicenseType, OSType, ResyncRequired, SqlServerLicenseType, TargetGeneration, TargetLocation, TargetNetworkId, *perc*

Get-AzMigrateServerReplication -ProjectName verint-gz-lab-azmigrate-eus -ResourceGroupName $ResourceGroup.ResourceGroupName -MachineName WIN10-CISCO-Clone|
      select CurrentJobStartTime,Health,MachineName, MigrationState, MigrationStateDescription, ReplicationStatus

     
#endregion

# Retrieve the updated status for a job
Get-AzMigrateJob -InputObject $job
Get-AzMigrateJob -ResourceGroupName verint-gz-lab-azmigrate -ProjectName verint-gz-lab-azmigrate-eus|select -First 5  #Worked
Get-AzMigrateJob -JobID 4a2abea7-2654-432c-8d8e-80894e72d0b1  #Error: Get-AzMigrateJob: Cannot bind argument to parameter 'JobName' because it is an empty string.
Get-AzMigrateJob -ProjectName verint-gz-lab-azmigrate-eus -ResourceGroupName verint-gz-lab-azmigrate -JobName b4ba4af2-5e84-45cd-841f-412c3ffdea63  #Works
Get-AzMigrateJob -JobID '/Subscriptions/<>/resourceGroups/verint-gz-lab-azmigrate/providers/Microsoft.RecoveryServices/vaults/ATLAZMIGRATE7393vault/replicationJobs/b4ba4af2-5e84-45cd-841f-412c3ffdea63' #Works



$MigrateJob = Start-AzMigrateServerMigration -InputObject $ReplicatingServer -TurnOffSourceServer  # Start migration for a replicating server and turn off source server as part of migration
Get-AzMigrateJob -InputObject $MigrateJob  #The on-prem VM turns off immediately
(Get-AzMigrateJob -InputObject $MigrateJob).Task #Shows individual tasks



#region remove replication and delete VM if the VM won't be used
$StopReplicationJob = Remove-AzMigrateServerReplication -InputObject $ReplicatingServer  # Stop replication for a migrated server Or 'complete migration' on the replicating item from the portal.

Get-AzMigrateJob -InputObject $StopReplicationJob
<#State                            : Succeeded
StateDescription                 : Completed
#>
Get-AzVM -ResourceGroupName GZ_Migrate_EUS -Name Attachments -Status  #Check if the VM shutdown
Remove-AzVM -ResourceGroupName GZ_Migrate_EUS -Name Attachments -Verbose #Deletes the shutdown runbook too.

#remove nic with NIC from VM's network profile
#remove disk with disk name from disk profile
#remove boot diagnostics storage container

Get-AzResource -ResourceGroupName GZ_Migrate_EUS -Name *Attachments*|FT
#endregion

#region image creation for template migration
New-AzGalleryImageDefinition -Location EastUS -ResourceGroupName GZ_Images_EUS -GalleryName GZ_Gallery_EUS -Name W10CiscoSoftphone  -Publisher VerintCommonOps -Offer Cisco -Sku Softphone `
         -OsState Specialized -OsType Windows -HyperVGeneration V2 -Verbose #Or v1

New-AzGalleryImageVersion -Location EastUS -ResourceGroupName GZ_Images_EUS -GalleryName GZ_Gallery_EUS -GalleryImageDefinitionName W10CiscoSoftphone -Name 0.0.1 `
          -SourceImageId (Get-AzVM -ResourceGroupName GZ_TEMPLATES_EUS -Name W10CiscoClone).Id -Verbose
#endregion

#region with the OS upgrade option SupportedOSVersions in Get-AzMigrateServerReplication will provided the valid values for '-OsUpgradeVersion'
Get-AzMigrateDiscoveredServer -ProjectName verint-gz-lab-azmigrate-eus -ResourceGroupName verint-gz-lab-azmigrate|? OperatingSystemDetailOSName -Like '*2008*'| select -First 1 |fl
(Get-AzMigrateDiscoveredServer -ProjectName verint-gz-lab-azmigrate-eus -ResourceGroupName verint-gz-lab-azmigrate|? OperatingSystemDetailOSName -Like '*2008*').count  #Output : 187

#Replication steps are same
$ReplicatingServer.ProviderSpecificDetail.SupportedOSVersion # Provides target upgrade OS version

Start-AzMigrateServerMigration -InputObject $ReplicatingServer -TurnOffSourceServer -OsUpgradeVersion 'Microsoft Windows Server 2012 (64-bit) (Datacenter or Standard edition)' -Verbose

Start-AzMigrateServerMigration -InputObject $ReplicatingServer -TurnOffSourceServer -OsUpgradeVersion $ReplicatingServer.ProviderSpecificDetail.SupportedOSVersion -Verbose
#This faile: Start-AzMigrateServerMigration: Cannot process argument transformation on parameter 'OsUpgradeVersion'. Cannot convert value to type System.String.
#endregion