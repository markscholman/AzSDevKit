#RUNAS ADMINISTRRATOR!
Install-Module Microsoft.AzureStack.ReadinessChecker
Import-Module Microsoft.AzureStack.ReadinessChecker

$subject = "C=US,ST=Washington,L=Redmond,O=Mark Scholman,OU=IT"

New-Item -ItemType Directory -Path .\AzureStackCSR -ErrorAction SilentlyContinue -Force
$outputDirectory = ".\AzureStackCSR"

$regionName = 'redmond'
$externalFQDN = 'asic.cloud'

# App Services
New-AzsCertificateSigningRequest -certificateType AppServices -RegionName $regionName -FQDN $externalFQDN -subject $subject -OutputRequestPath $OutputDirectory

# DBAdapter
New-AzsCertificateSigningRequest -certificateType DBAdapter -RegionName $regionName -FQDN $externalFQDN -subject $subject -OutputRequestPath $OutputDirectory

# EventHubs
New-AzsCertificateSigningRequest -certificateType EventHubs -RegionName $regionName -FQDN $externalFQDN -subject $subject -OutputRequestPath $OutputDirectory

# IoTHub
New-AzsCertificateSigningRequest -certificateType IoTHub -RegionName $regionName -FQDN $externalFQDN -subject $subject -OutputRequestPath $OutputDirectory