Get-AzSqlVM |select -First 1 |fl *

(Get-AzSqlVM |? Location -EQ 'EastUS').count

((Get-AzSqlVM |? Location -EQ 'EastUS').Name|%{Get-AzVM -Name $PSItem -Status}|? PowerState -NE 'VM running').count  #SQL VMs shutdown
#Can take a long time since it queries the status of each VM

#Total cost of only the unused SQL VMs in one subscription?
$SqlVms=(Get-AzSqlVM |? Location -EQ 'EastUS').Name|%{Get-AzVM -Name $PSItem -Status}|? PowerState -NE 'VM running'
$usageReport = Get-AzConsumptionUsageDetail -StartDate 2023-09-01 -EndDate 2023-09-30 -IncludeAdditionalProperties | Where-Object { $_.InstanceId -in $sqlVms.Id }
[Math]::Round(($usageReport| Measure-Object PretaxCost -Sum).Sum,0)