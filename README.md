1. [Deploy Win11 Arm VM](https://ayanmullick.github.io/AzIaaS/?path=https://raw.githubusercontent.com/Ayanmullick/AzIaaS/master/Blog/DeployWindows11ArmVM.md){:target="_blank"}
2. 2nd blog
3. 3rd blog  

   

## Script Installation steps

```ps
$Script   = 'Hello-World' #Replace with Script name
$DestPath = [Environment]::GetFolderPath('MyDocuments')+"\PowerShell\Scripts"  #User's default script folder

(New-Object System.Net.WebClient).DownloadFile("https://github.com/Ayanmullick/AzIaaS/raw/master/$Script.ps1","$DestPath\$Script.ps1")   #Download script
If (($env:PATH -split ';') -notcontains $DestPath) {$env:Path += ";$DestPath"} #Add Script folder path to environment variable, if not present, for intellisense.
```
