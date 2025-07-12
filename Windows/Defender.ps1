Set-MpPreference -DisableBehaviorMonitoring $false
Set-MpPreference -ScanScheduleDay 1

Set-MpPreference -ScanScheduleTime 22:00:00


#Gets Vm's in a resource group, enables real time protection and configures AV scanning for 5:00 AM on Sundays
(Get-AzureRmVM -ResourceGroupName NLGSUSUTMRASRG2).Name|
                ForEach-Object {Invoke-Command -ComputerName $PSItem -ScriptBlock {Set-MpPreference -DisableBehaviorMonitoring $false -Verbose;Set-MpPreference -ScanScheduleDay 1 -Verbose;Set-MpPreference -ScanScheduleTime 05:00:00 -Verbose}
                                }


Invoke-Command -ComputerName NLGDVJAMVM1 -ScriptBlock {Get-MpPreference}

Get-WmiObject -Namespace "root\Microsoft\SecurityClient" AntimalwareHealthStatus


mpcmdrun -getfiles  #Gets all the defender related logs