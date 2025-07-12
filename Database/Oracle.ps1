<#https://www.oracle.com/database/technologies/instant-client/downloads.html
Download basic and ODBC packages:  https://www.oracle.com/database/technologies/instant-client/winx64-64-downloads.html
Download and unzip both the Basic and ODBC packages for the same version into a single folder. For example, with version 23.8:
C:\oracle\instantclient_23_8\
  ├─ oci.dll, oraociei23.dll, etc. (from Basic)
  └─ odbc_install.exe, sqora32.dll, etc. (from ODBC)

#>
<#
PS C:\temp\instantclient-basic-windows.x64-23.8.0.25.04\instantclient_23_8> .\odbc_install.exe
Oracle ODBC Driver is installed successfully.
#>
PS C:\temp\instantclient-basic-windows.x64-23.8.0.25.04\instantclient_23_8> Get-OdbcDriver | Where-Object Name -like "*Oracle*"
<#Name      : Microsoft ODBC for Oracle
Platform  : 32-bit
Attribute : {[ConnectFunctions, YYY], [APILevel, 1], [DriverODBCVer, 02.50], [Setup, %WINDIR%\system32\msorcl32.dll]…}

Name      : Oracle in instantclient_23_8
Platform  : 64-bit
Attribute : {[SQLLevel, 1], [APILevel, 1], [DriverODBCVer, 03.51], [Setup, C:\temp\instantclient-basic-windows.x64-23.8.0.25.04\instantclient_23_8\SQORAS32.DLL]…}
#>

#Start-Run-Odbc 64 bit: 'Oracle in instantclient_23_8' should show up under the 'Drivers' tab


#region Oracle authentication validation
Add-Type -AssemblyName System.Data
$connString = "Driver={Oracle in instantclient_23_8};Dbq=<>:1521/adw;Uid=<>;Pwd=<>;"
$connection = New-Object System.Data.Odbc.OdbcConnection($connString)
try {$connection.Open()
     Write-Output "✔ Oracle ODBC connection succeeded."
     $connection.Close()
} catch { Write-Output "❌ Oracle ODBC connection failed:`n$($_.Exception.Message)"}

#✔ Oracle ODBC connection succeeded.  #Works
#endregion

#region Fetch the first row from a table. Works.  'adw' is the Oracle instance name and it's case sensitive. 'FACILITY_DIMENSION' is the table name. 
Add-Type -AssemblyName System.Data
$conn = New-Object System.Data.Odbc.OdbcConnection("Driver={Oracle in instantclient_23_8};Dbq=<>:1521/adw;Uid=<>;Pwd=<>;")

try {
    $conn.Open()
    Write-Host "✔ Connected"
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = "SELECT * FROM ADW.FACILITY_DIMENSION WHERE ROWNUM = 1"
    $r = $cmd.ExecuteReader()
    if ($r.Read()) { 0..($r.FieldCount-1) | ForEach-Object { "$($r.GetName($_)) = $($r.GetValue($_))" } }
    else { Write-Host "⚠ No rows found." }
    $r.Close(); $conn.Close()
} catch {  Write-Host "❌ Connection failed:`n$($_.Exception.Message)"}

#endregion