#Set owner for migrated AzVM in SNOW Commander

#OS healthcheck
#Application healthcheck

# Organisation, Owner contact, AlwaysOn tagging
$mergedTags = @{"OwnerContact"="<>@<>.com"; "Organization"="Engineering - Text Capture - Weybridge";"Alwayson"="No"}
$VM = Get-AzVM -ResourceGroupName $TargetResourceGroup.ResourceGroupName -Name $ReplicatingServer.MachineName
Get-AzResource -ResourceGroupName $TargetResourceGroup.ResourceGroupName -Name $VM.Name -ResourceType Microsoft.Compute/virtualMachines| Update-AzTag -Tag $mergedTags -Operation Merge -Verbose -ErrorAction Stop

#Auto-shutdown config
$properties = @{"status" = "Enabled"; "taskType" = "ComputeVmShutdownTask"; "dailyRecurrence" = @{"time" = "1800" }; "timeZoneId" = "Eastern Standard Time";
    "notificationSettings" = @{"status" = "Enabled"; "timeInMinutes" = 30; "emailRecipient"= "<>@<>.com"; "notificationLocale"= "en"}
    "targetResourceId" = $VM.Id
                }
New-AzResource -ResourceId ($TargetResourceGroup.ResourceId+'/providers/microsoft.devtestlab/schedules/shutdown-computevm-'+$VM.Name) -Location $VM.Location -Properties $properties -Force -Verbose

(Invoke-AzVMRunCommand -ResourceId $VM.Id -CommandId RunPowerShellScript -ScriptString "(GCim win32_operatingsystem).lastbootuptime").Value[0].Message  #Basic health check
#Removed owner from on-prem VM
#Set it's Lifecycle management- Expiry group to 'Expired VM group'
#Stopped replication for the VM in Azure.
#Moved migrated VM and it’s associated resources to the GZ_Payload_EUS resource group.


#Set the AzNic IP config. to be static, as requested by the user.

$Nic = Get-AzNetworkInterface -ResourceGroupName 'GZ_Payload_EUS' -Name 'nic-IC-HFR10-TWILIO-00'
$Nic.IpConfigurations[0].PrivateIpAllocationMethod = "Static"
$Nic|Set-AzNetworkInterface

#Template
#Delete Azure migrated VM, Azure template test VM, VMWare Clone VM
#Unpublish SNOW Commander template