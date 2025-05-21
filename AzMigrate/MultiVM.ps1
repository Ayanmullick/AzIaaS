$CesDb = Import-Excel -Path 'C:\Users\AyanMullick\OneDrive - Mullick\PowerShell\Verint\MoveToCloud.xlsx' -WorksheetName Sheet1| ? 'Organization Name' -EQ 'Engineering - CES DB'|
                select -Property Name,CPU,RAMGb,StorageGb,Host

#region Gets then name discarding the IP address. Get-AzMigrateDiscoveredServer doesn't work for all otherwise               
#$CesDb.Name -replace '^([^_ ]+)(?= [0-9])', '$1'  
$regex = "\s*\([^)]+\)|_\d+\.\d+\.\d+\.\d+" #Regex gets the name from left and ends with underscore or space if succeeded by number. And Discards what's after.
$VMnames = $CesDb.Name -replace $regex
#v2 worked
$VMnames = $CesDb.Name -replace '(\w+)(\s*\([^)]+\)|_\d+\.\d+\.\d+\.\d+)', '$1'
#endregion .TrimEnd() doesn't accept regex.

$VMNames = 'VirtusaPoseidon','TestMinh','VirtusaApollo','VM0190','ProTestMT'  #Or enter names manually

$prop = "DisplayName","VMFqdn","Firmware",@{n='RAMGb';e={[Math]::Ceiling($_.AllocatedMemoryInMb/1024)}},@{n='Cores';e={$_.NumberOfProcessorCore}},
         @{n='IP';e={$_.NetworkAdapter|ForEach-Object { "$($_.Label):$($_.IPAddressList)| " } | Out-String -NoNewline}},@{n='IPType';e={$_.NetworkAdapter[0].IPAddressType}},
         @{n='DiskGb';e={$_.Disk |ForEach-Object { "$($_.Lun):$($_.MaxSizeInByte/1Gb)| " } | Out-String -NoNewline}},"OperatingSystemDetailOSName","OperatingSystemDetailOSType"


$VMnames |% { Get-AzMigrateDiscoveredServer -ResourceGroupName verint-gz-lab-azmigrate -ProjectName verint-gz-lab-azmigrate-eus  -DisplayName $PSItem}| ft -Property $prop 

#If no processing needed for name. 
$Recorder.Name |% { Get-AzMigrateDiscoveredServer -ResourceGroupName verint-gz-lab-azmigrate -ProjectName verint-gz-lab-azmigrate-eus -ApplianceName ATLAZMIGRATE -DisplayName $PSItem}| ft -Property $prop


$OrgDiscoveredServers = $VMnames |% { Get-AzMigrateDiscoveredServer -ResourceGroupName verint-gz-lab-azmigrate -ProjectName verint-gz-lab-azmigrate-eus  -DisplayName $PSItem}

$TargetResourceGroup =New-AzResourceGroup -Location EastUS  -Name Engineering-RecorderEntrepreneurs -Verbose
$TargetVirtualNetwork = Get-AzVirtualNetwork -Name verint-lab-eus-lab-vnet

#-Verbose Creates long output
$OrgDiscoveredServers | % {New-AzMigrateServerReplication -InputObject $PSItem -TargetResourceGroupId $TargetResourceGroup.ResourceId -TargetNetworkId $TargetVirtualNetwork.Id -LicenseType WindowsServer `
    -OSDiskID $PSItem.Disk[0].Uuid -TargetSubnetName $TargetVirtualNetwork.Subnets[2].Name -DiskType Standard_LRS -TargetVMName $_.DisplayName -TargetVMSize ('Standard_B'+$_.NumberOfProcessorCore+'ms') }                        

#Check Replication status
$OrgDiscoveredServers|%{Get-AzMigrateServerReplication -ResourceGroupName verint-gz-lab-azmigrate -ProjectName verint-gz-lab-azmigrate-eus -MachineName $PSItem.DisplayName}|   
                select MachineName, ReplicationStatus, MigrationState,MigrationStateDescription, @{n='Initial%'; e={$_.ProviderSpecificDetail.InitialSeedingProgressPercentage}}, `
                        @{n='Migrate%'; e={$_.ProviderSpecificDetail.MigrationProgressPercentage}}| 
                                FT

                
#region Migrate VM
$ReplicatingServers = $OrgDiscoveredServers | %{Get-AzMigrateServerReplication -ResourceGroupName verint-gz-lab-azmigrate -ProjectName verint-gz-lab-azmigrate-eus -MachineName $PSItem.DisplayName}
$ReplicatingServers|ft MachineName, Health, MigrationState, MigrationStateDescription, ReplicationStatus,CurrentJobName #View replicating servers

$ReplicatingServers | % {Start-AzMigrateServerMigration -InputObject $PSItem -TurnOffSourceServer -Verbose}
#Check migration status
(Get-AzMigrateJob -ResourceGroupName verint-gz-lab-azmigrate -ProjectName verint-gz-lab-azmigrate-eus).Where({$_.ScenarioName -eq 'Migrate' -and $_.TargetObjectName -eq 'KR-W2016-3'})  #Worked

#Didn't work
$ReplicatingServers| % {
        (Get-AzMigrateJob -ResourceGroupName verint-gz-lab-azmigrate -ProjectName verint-gz-lab-azmigrate-eus).Where({$_.ScenarioName -eq 'Migrate' -and $_.TargetObjectName -eq "$PSItem.MachineName"})}


#Gets name and IP of VMs
Get-AzVM  -ResourceGroupName $TargetResourceGroup.ResourceGroupName|
        select Name, @{n='AzureIP'; e={(Get-AzNetworkInterface -ResourceId $PSItem.NetworkProfile.NetworkInterfaces.Id).IpConfigurations.PrivateIpAddress}}


$ReplicatingServers |% {Remove-AzMigrateServerReplication -InputObject $PSItem}
#endregion



#region Post Migration Worked
$mergedTags = @{"OwnerContact"="<>@<>.com"; "Organization"="Engineering-RecorderEntrepreneurs";"Alwayson"="No"}
$OrgDiscoveredServers| %{Get-AzResource -ResourceGroupName $TargetResourceGroup.ResourceGroupName -Name $_.DisplayName -ResourceType Microsoft.Compute/virtualMachines|
                                 Update-AzTag -Tag $mergedTags -Operation Merge -Verbose -ErrorAction Stop
                        }
#Basic health check
(Get-AzVM -ResourceGroupName GZ_Extra_EUS -Status).Where({$_.PowerState -Match 'Running' -and $_.StorageProfile.OsDisk.OsType -eq 'Windows'}) | ForEach-Object {
        $Run = Invoke-AzVMRunCommand -ResourceGroupName $_.ResourceGroupName -VMName $($script:VMName = $_.Name;$VMName) -CommandId 'RunPowerShellScript' -ScriptString "(Get-CimInstance Win32_OperatingSystem).LastBootUpTime"
        Write-Output "$VMName started $($Run.Value[0].Message)"
     }
#endregion        