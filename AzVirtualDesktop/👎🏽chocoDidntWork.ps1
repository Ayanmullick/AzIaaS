
#region choco
# Agent (must provide your host pool token)
choco install wvd-agent -y --params "'/REGISTRATIONTOKEN:<YOUR_TOKEN>'"

# Bootloader
choco install wvd-boot-loader -y



$script = @'
Install-PackageProvider -Name Chocolatey -Force -Scope AllUsers -Verbose
Register-PackageSource -Name chocolatey -ProviderName Chocolatey -Location 'https://community.chocolatey.org/api/v2/' -Trusted -Verbose
'@



$token = '<YOUR_TOKEN>'

# Agent (pass REGISTRATIONTOKEN via Chocolatey provider's -Params)
Install-Package -Name wvd-agent -ProviderName Chocolatey -Source chocolatey -ForceBootstrap -Force -AcceptLicense -Verbose -Params ('"/REGISTRATIONTOKEN:{0}"' -f $token)

# Boot Loader
Install-Package -Name wvd-boot-loader -ProviderName Chocolatey -Source chocolatey -ForceBootstrap -Force -AcceptLicense -Verbose
#endregion
