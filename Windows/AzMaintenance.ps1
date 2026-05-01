Get-AzMaintenanceUpdate -ResourceGroupName '<>-cus-services-rg' -ProviderName Microsoft.Compute -ResourceType virtualMachines -ResourceName '<>'
<#MaintenanceScope    : Extension
ImpactType          : Restart
Status              : Completed
ImpactDurationInSec : 3600
ResourceId          :
/subscriptions/<>/resourcegroups/<>-cus-services-rg/providers/Microsoft.Compute/virtualMachines/<>


MaintenanceScope    : OSImage
ImpactType          : Restart
Status              : Pending
ImpactDurationInSec : 3600
ResourceId          :
/subscriptions/<>/resourcegroups/<>-cus-services-rg/providers/Microsoft.Compute/virtualMachines/<>
#>


Get-AzConfigurationAssignment -ResourceGroupName '<>-cus-services-rg' -ProviderName 'Microsoft.Compute' -ResourceType 'virtualMachines' -ResourceName '<>'
#<no output>






$vms = Get-AzVM -ResourceGroupName '<>-cus-services-rg'

foreach ($vm in $vms) {
    try {
        $assignment = Get-AzConfigurationAssignment `
            -ResourceGroupName $vm.ResourceGroupName `
            -ResourceType 'virtualMachines' `
            -ResourceName $vm.Name `
            -ProviderName 'Microsoft.Compute'

        if ($assignment) {
            Write-Host "$($vm.Name): Patch Config Assigned -> $($assignment.Properties.MaintenanceConfigurationId)"
        } else {
            Write-Host "$($vm.Name): No Patch Config Assigned"
        }
    } catch {
        Write-Host "$($vm.Name): Error or No Assignment"
    }
}
<#azcrtdcadc01: No Patch Config Assigned
azcrtdccpa01: No Patch Config Assigned
#>


Search-AzGraph -Query @"
resources
| where type == 'microsoft.compute/virtualmachines'
| extend orchestrationMode = tostring(properties.extended.instanceView.patchStatus.orchestrationMode)
| project name, resourceGroup, orchestrationMode
"@