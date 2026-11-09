#region Copy snapshot to storage any account
$storageAccountName = "ayn"
$storageAccountKey = '<>'
$absoluteUri = 'https://<>.blob.core.windows.net/<>/'
$destContainer = 'vhds'
$blobName = 'server.vhd'

$destContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
Start-AzureStorageBlobCopy -AbsoluteUri $absoluteUri -DestContainer $destContainer -DestContext $destContext -DestBlob $blobName
#endregion


#region Copy a managed disk to storage any account
$sas = Grant-AzDiskAccess -ResourceGroupName W10VmRG -DiskName W10D  -DurationInSecond 3600 -Access Read
$storageAccountContext = New-AzStorageContext -StorageAccountName diskexport1 -StorageAccountKey '<>'
New-AzStorageContainer -Context $storageAccountContext -Name diskexportcont -Verbose
Start-AzStorageBlobCopy -AbsoluteUri $sas.AccessSAS -DestContainer diskexportcont -DestContext $storageAccountContext -DestBlob w10.vhd

$a= Get-AzStorageBlobCopyState -Container diskexportcont -Blob w10.vhd -Context $storageAccountContext
($a.BytesCopied/$a.TotalBytes).ToString("P")  #Output: 40.389%
#endregion



#region Expand a vhd
$rgName = 'Infra_VMs'
$vmName = 'A20VL001'

$vm = Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName

Stop-AzureRmVM -ResourceGroupName $rgName -Name $vmName

$vm.StorageProfile.OSDisk.DiskSizeGB = 2048
Update-AzureRmVM -ResourceGroupName $rgName -VM $vm

Start-AzureRmVM -ResourceGroupName $rgName -Name $vmName
#endregion