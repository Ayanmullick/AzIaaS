Install-Module -Name VMware.PowerCLI

Connect-VIServer -Server '<>.lab.local' -User amullick@lab.local -Password '<>' -Verbose   


$RApiA = Import-Excel -Path '.\Users\Ayan.Mullick\OneDrive - Verint Systems Ltd\Downloads\move to cloud (version 1).xlsb.xlsx' -WorksheetName Sheet1| ? 'Organization Name' -EQ 'Engineering - Recorders API - Atlanta'

$RApiA|ft Name,@{n='Status'; e={(Get-VM -Name $PSItem.Name).PowerState}},CPU,RAMGb,StorageGb, @{n='Snapshots'; e={(Get-Snapshot -VM $PSItem.Name).count}}


Get-VM -Name WIN10-TEMP-AVAYA_new

Get-Datastore -Name N2_DS_GZ_01

New-VM -Name WIN10-TEMP-AVAYA_Clone -VM (Get-VM WIN10-TEMP-AVAYA_new) -VMHost '<>.lab.local' -Verbose #Cloning Worked # -Datastore (Get-Datastore $tgtDatastoreName) -RunAsync

Get-VM -Name WIN10-TEMP-AVAYA_Clone  #Should capture resource pool level details too. #ResourcePoolId and ResourcePool # And  VApp
Get-VMGuest -VM WIN10-CISCO-Clone|FL #OS level details.

Get-VMGuest -VM WIN10-CISCO-Clone| Get-VMGuestDisk |FL *
Get-HardDisk -VM 'Clone-Consolidate-048298-2566'|select  Parent, Name, CapacityGB, DiskType

Get-NetworkAdapter -VM WIN10-CISCO-Clone|FL

#region Update VMware tools
Start-VM WIN10-CISCO-Clone -Verbose
Update-Tools -VM WIN10-CISCO-Clone -Verbose
Mount-Tools -VM WFO152HFR4Sql2014LClone -Verbose

#Update in bulk
$WFMVMware = Get-VM -Name $WFMVMs.Name
$WFMVMware|? PowerState -EQ 'PoweredOn'
Update-Tools $WfmWindowsOn.Name -Verbose

#endregion


Get-Snapshot -VM HFR10BASE|sort Created -Descending|Remove-Snapshot -Confirm:$false -Verbose
'mate-edm-export', 'mate-hfr9-for-MT'|% {Get-Snapshot -VM $PSItem|Sort-Object Created -Descending|Remove-Snapshot -Confirm:$false -Verbose}


#region Find weather the OS drive is dynamic
Invoke-VMScript -VM WIN10-TEMP-AVAYA_Clone -ScriptType Powershell -ScriptText "Get-Process" -GuestUser administrator -GuestPassword '<>'

Invoke-VMScript -VM WIN10-TEMP-AVAYA_Clone -ScriptType Powershell -ScriptText "Get-CimInstance Win32_DiskPartition | Select-Object DeviceID, Type" -GuestUser administrator -GuestPassword '<>'

#Didn;t work because of the '' issue
Invoke-VMScript -VM WIN10-TEMP-AVAYA_Clone -ScriptType Powershell -ScriptText 'Get-CimInstance Win32_DiskPartition -filter "Type='Logical Disk Manager'"' -GuestUser administrator -GuestPassword '<>'

Get-VM -Name 'Hai-3564','Hai-MT','HFR10BASE','Luca-hfr10','mate-edm-export','mate-hfr9-for-MT','RAKERSHFR9','RicsiV2','VM997' | 
        select Name,NumCpu,MemoryGB,VMHost,Notes, PowerState, @{n='Snapshot';e={(Get-Snapshot -VM $PSItem).count}}, `
            @{n='Boot';e={(Invoke-VMScript -VM $PSItem -ScriptType Powershell -ScriptText '(Get-CimInstance Win32_DiskPartition| ?{$PSItem.BootPartition -eq $True}).Type' -GuestUser administrator -GuestPassword '<>').ScriptOutput}} |
             Format-Table -Wrap -AutoSize

#region 3 creds
(Invoke-VMScript -VM Hai-3564 -ScriptType Powershell -ScriptText '(Get-CimInstance Win32_DiskPartition| ?{$PSItem.BootPartition -eq $True}).Type' -GuestUser administrator -GuestPassword '<>').ScriptOutput
(Invoke-VMScript -VM Hai-3564 -ScriptType Powershell -ScriptText '(Get-CimInstance Win32_DiskPartition| ?{$PSItem.BootPartition -eq $True}).Type' -GuestUser ap2admin -GuestPassword '<>').ScriptOutput
(Invoke-VMScript -VM TestMinh -ScriptType Powershell -ScriptText '(Get-CimInstance Win32_DiskPartition| ?{$PSItem.BootPartition -eq $True}).Type' -GuestUser svcverint -GuestPassword '<>').ScriptOutput
#endregion


#endregion

Stop-VM WFO151RuTClone -Verbose


(Get-VM -Name DockerDJ | Get-View).Runtime  #Has last boot time etc
#  .Capability #has  SecureBootSupported| ExtensionData.Capability in VM object
# .Config # CreateDate, Firmware |  .Files VM and snapshot paths |.Hardware has hardware config

Set-PowerCLIConfiguration -WebOperationTimeoutSeconds 3600 -Confirm:$false  #restart session
Get-VIEvent -Entity DockerDJ -MaxSamples 10 -Verbose  

#region Get the last boot time of a VMware VM from Vcenter
$vm = Get-VM -Name ConnorVM
Get-VIEvent -Entity $VM -Types Info -Start (Get-Date).AddDays(-7) | Where-Object {$_.FullFormattedMessage -match "Task: Power On"} | Sort-Object -property createdTime -Descending  #Worked
(Get-VIEvent -Entity 'ie-qa-desktop6 Avaya 330090' -Types Info).Where({$_.FullFormattedMessage -match "Power On"})|Sort createdTime -Descending |select -First 3

Get-VM -Name DockerDJ| Select Name, @{N='LastBootTime';E={($_ | Get-VIEvent -MaxSamples 1 -Start (Get-Date).AddDays(-1) -Types Info -EventTypeId 'VmPoweredOnEvent' |
         Select CreatedTime | Sort-Object -Descending | Select -First 1).CreatedTime}}

#region  v2
Get-VM -Name $WFMVMs.Name -ErrorAction SilentlyContinue|? VApp -EQ $null|select Name,NumCpu,MemoryGB,VMHost,VApp, PowerState|Format-Table -Wrap -AutoSize

$L3VMs = Import-Excel -Path '.\Users\Ayan.Mullick\OneDrive - Verint Systems Ltd\Downloads\AugList.xlsx'| ? {$_.'Organization Name' -Like '*L3*' -and $_.'Keep it on-prem?' -ne 'Yes'}



$L3VMware = Get-VM -Name $L3VMs.Name -ErrorAction SilentlyContinue|? VApp -EQ $null

$LastBoot = $L3VMware.Name|%{(Get-VIEvent -Entity $PSItem -Types Info).Where({$_.FullFormattedMessage -match "Task: Power On"})|Sort createdTime -Descending |select -First 1 -Property @{n= 'VM';e={$_.VM.Name}}, CreatedTime}


$PowerOff = Import-Excel -Path '.\Users\Ayan.Mullick\OneDrive - Verint Systems Ltd\Downloads\vmBackingCsvExport.xlsx' -ImportColumns 1,8  #This file is the SNOW Commander Inventory export
($PowerOff.Where({$_.Name -EQ 'DC-046395-SSAML-0004'})).'Powered Off Since'
Get-VApp L1_C_22_19_15.2.D_AI_HFR10_AC_MT_SAML-005|Get-VM|select Name,NumCpu,MemoryGB,VMHost,VApp, PowerState, @{n='PowerOffTime';e={($PowerOff.Where({$_.Name -EQ 'DC-046395-SSAML-0004'})).'Powered Off Since'}}
$PowerOff|? {$VMs.Name -EQ $PSItem.Name}

#endregion


#endregion


Get-ResourcePool

Get-VApp SOAK_SAML_onDemand-8001|fl *
Get-VApp SOAK_SAML_onDemand-8001|select -ExpandProperty ExtensionData
Get-VApp SOAK_SAML_onDemand-8001|Get-VM #Gets the VMs in the VApp


#region disable auto vmotion
(Get-VM -Name VirtusaApollo).VMHost.Parent  #Cluster a VM is on
(Get-VM -Name VirtusaApollo).DrsAutomationLevel  #Tells you if migration is enabled
Get-Cluster GZ-GSSP-ATL2|fl *
Set-VM -VM KafkaKata2 -DrsAutomationLevel Manual -Confirm:$false -Verbose #Will disable auto VMotion

#endregion



Set-PowerCLIConfiguration -InvalidCertificateAction Prompt -Verbose
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $true -Verbose



Get-VM KR-W2016-1| select Name,NumCpu,MemoryGB,VMHost,Notes, PowerState
Get-Snapshot -VM KR-W2016-1 | Select-Object VM, Name, Created
Get-VMGuest -VM WIN10-CISCO-Clone|FL #OS leevl details.
Get-VMGuest -VM WIN10-CISCO-Clone| Get-VMGuestDisk |FL *
Get-NetworkAdapter -VM WIN10-CISCO-Clone|FL

Start-VM WIN10-CISCO-Clone -Verbose
Update-Tools -VM WIN10-CISCO-Clone -Verbose
Mount-Tools -VM WFO152HFR4Sql2014LClone -Verbose

Get-HardDisk -VM KR-W2016-1|select -First 1 Parent, Name, CapacityGB, DiskType
(Get-HardDisk -VM KR-W2016-1|select -First 1).ExtensionData.backing  #No dynamic disk info


#region Get VM properties with snapshot count and if the Boot volume is dynamic
Get-CimInstance Win32_DiskPartition | Select-Object DeviceID, Type
Get-CimInstance -ClassName Win32_DiskPartition -Filter ‘BootPartition = 1’
Invoke-VMScript -VM WIN10-TEMP-AVAYA_Clone -ScriptType Powershell -ScriptText "Get-CimInstance Win32_DiskPartition | Select-Object DeviceID, Type" -GuestUser administrator -GuestPassword '<>'  #Worked

#GPT shows as GPT under Type . If the boot partion is dynamic the type would be 'Logical Disk Manager'

Get-VM -Name 'Hai-3564','Hai-MT','HFR10BASE','Luca-hfr10','mate-edm-export','mate-hfr9-for-MT','RAKERSHFR9','RicsiV2','VM997' | 
        select Name,NumCpu,MemoryGB,VMHost,Notes, PowerState, @{n='Snapshot';e={(Get-Snapshot -VM $PSItem).count}}, `
            @{n='Boot';e={(Invoke-VMScript -VM $PSItem -ScriptType Powershell -ScriptText '(Get-CimInstance Win32_DiskPartition|? BootPartition).Type' -GuestUser administrator -GuestPassword '<>').ScriptOutput}} |
             Format-Table -Wrap -AutoSize
#endregion



#Get info from within a VCenter VM
Invoke-VMScript -VM windows-vm -ScriptType Powershell -ScriptText "Get-Process"

#region Get and Remove snapshots
Get-Snapshot -VM HFR10BASE|sort Created -Descending|Remove-Snapshot -Confirm:$false -Verbose  #Sort by created so it merges the last snapshot first and then the next ones

'mate-edm-export', 'mate-hfr9-for-MT'|% {Get-Snapshot -VM $PSItem|Sort-Object Created -Descending|Remove-Snapshot -Confirm:$false -Verbose}
#endregion