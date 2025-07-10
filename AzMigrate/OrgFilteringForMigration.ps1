#region VM Migration filtering for one OrgDRSEnabled 

$WFMVMs = Import-Excel -Path '.\Users\Ayan.Mullick\<> Systems Ltd\Downloads\AugList.xlsx'| ? 'Organization Name' -Like '*WFM*Gla*'
$WFMVMs = Import-Excel -Path '.\Users\Ayan.Mullick\<> Systems Ltd\Downloads\AugList.xlsx'| ? {$_.'Organization Name' -Like '*WFM*Gla*' -and $_.'Keep it on-prem?' -ne 'Yes'}
$WFMVMs = Import-Excel -Path '.\Users\Ayan.Mullick\<> Systems Ltd\Downloads\AugList.xlsx'|  ? {$_.'Organization Name' -Like '*WFM*Gla*' -and $_.'Keep it on-prem?' -ne 'Yes' -and $_.'Move to Azure?' -eq $null}

#Get-VM -Name $WFMVMs.Name| select Name,NumCpu,MemoryGB,VMHost,PowerState, @{n='Snapshot';e={(Get-Snapshot -VM $PSItem).count}} |Format-Table -Wrap -AutoSize
Get-VM -Name $WFMVMs.Name| select Name,NumCpu,MemoryGB,VMHost,PowerState,@{n='OS';e={(Get-VMGuest -VM $PSItem).OSFullName}}, @{n='Snapshot';e={(Get-Snapshot -VM $PSItem).count}} |Format-Table -Wrap -AutoSize


Get-VM -Name $WFMVMs.Name|select Name,NumCpu,MemoryGB,VMHost,VApp, PowerState,@{n='Tools';e={$_.Guest.ToolsVersion}},@{n='OS';e={$_.Guest.ConfiguredGuestId}},@{n='OSFullName';e={$_.Guest.OSFullName}},
        @{n='IPAddress';e={$_.Guest.IPAddress -like '*.*'}},@{n='Snapshot';e={(Get-Snapshot -VM $PSItem).count}} | Sort OSFullName, OS|Format-Table -Wrap -AutoSize


#,@{n='Drives';e={$_.Guest.Disks.count}}  
#,@{n='Disks';e={(Get-HardDisk -VM $PSItem).count}}
#Without snapshots
Get-VM -Name $WFMVMs.Name|select Name,NumCpu,MemoryGB,VMHost,VApp, PowerState,@{n='Tools';e={$_.Guest.ToolsVersion}},@{n='OS';e={$_.Guest.ConfiguredGuestId}},@{n='OSFullName';e={$_.Guest.OSFullName}},
         @{n='IPAddress';e={$_.Guest.IPAddress -like '*.*'}},@{n='Disks';e={(Get-HardDisk -VM $PSItem).count}} | Sort OSFullName, OS|Format-Table

#The Windows VM's powered on
$WfmWindowsOn = Get-VM -Name $WFMVMs.Name| select Name,NumCpu,MemoryGB,VMHost,PowerState,
        @{n='OS';e={$($script:OS=Get-VMGuest -VM $PSItem;$OS).ConfiguredGuestId}},@{n='OSFullName';e={$OS.OSFullName}}, @{n='Snapshot';e={(Get-Snapshot -VM $PSItem).count}} |
                ? {$_.PowerState -EQ 'PoweredOn' -and $_.OS -like 'windows*'}  #Sort OSFullName, OS|Format-Table -Wrap -AutoSize

#endregion




$OctVms = Import-Excel -Path '.\Users\Ayan.Mullick\<> Systems Ltd\Downloads\Move to Azure - 1400.xlsx' -WorksheetName Sheet1| ? { ($_.'Keep it on-prem?' -eq 'No' -or $_.'Keep it on-prem?' -eq $null) -and $_.'DevOps Engineer working on Migration' -EQ $null }
$OctVms| Group-Object 'Organization Name'|sort Count -Descending

#Filters: Ms\3rd party supported, If part of Vapp, OS dynamic disk, Powered Off since

Get-VM -Name $Jakarta.Name|select Name,NumCpu,MemoryGB,VMHost, PowerState,@{n='OSFullName';e={$_.Guest.OSFullName}},@{n='OS';e={$_.Guest.ConfiguredGuestId}} |
        ? {$_.OS -like '*Windows7*' -or $_.OS -like '*8Server*'}| Sort OSFullName, OS|Export-Excel -Path C:\temp\Jakarta.xlsx -WorksheetName Unsupported

