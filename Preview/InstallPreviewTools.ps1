Get-Module -Name Azure* -ListAvailable | Uninstall-Module -Force -Verbose -ErrorAction Continue
Get-Module -Name Azs.* -ListAvailable | Uninstall-Module -Force -Verbose -ErrorAction Continue
Get-Module -Name Az.* -ListAvailable | Uninstall-Module -Force -Verbose -ErrorAction Continue


Install-Module -Name Az.BootStrapper -Force -AllowPrerelease
Install-AzProfile -Profile 2019-03-01-hybrid -Force
Install-Module -Name AzureStack -RequiredVersion 2.0.0-preview -AllowPrerelease

Add-AzEnvironment -Name "AzureStackAdmin" -ArmEndpoint "https://adminmanagement.local.azurestack.external" `
  -AzureKeyVaultDnsSuffix adminvault.local.azurestack.external `
  -AzureKeyVaultServiceEndpointResourceId https://adminvault.local.azurestack.external

$AuthEndpoint = (Get-AzEnvironment -Name "AzureStackAdmin").ActiveDirectoryAuthority.TrimEnd('/')
$AADTenantName = "asiccloud.onmicrosoft.com"
$TenantId = (Invoke-RestMethod "$($AuthEndpoint)/$($AADTenantName)/.well-known/openid-configuration").issuer.TrimEnd('/').Split('/')[-1]
Add-AzAccount -EnvironmentName "AzureStackAdmin" -TenantId $TenantId -UseDeviceAuthentication

Get-AzSAlert

Get-AzResourceGroup
