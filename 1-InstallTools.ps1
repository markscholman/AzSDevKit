Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
# Install the AzureRM.BootStrapper module. Select Yes when prompted to install NuGet
Install-Module -Name AzureRM.BootStrapper -Scope CurrentUser -Force

# Install and import the API Version Profile required by Azure Stack Hub into the current PowerShell session.
Use-AzureRmProfile -Profile 2019-03-01-hybrid -Force -Scope CurrentUser
Install-Module -Name AzureStack -RequiredVersion 1.8.1 -Scope CurrentUser -Force

# Download the tools archive.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
invoke-webrequest -Uri https://github.com/Azure/AzureStack-Tools/archive/master.zip -OutFile master.zip

# Expand the downloaded files.
expand-archive master.zip -DestinationPath . -Force
