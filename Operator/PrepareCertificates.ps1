#RUNAS ADMINISTRATOR!
Install-Module Microsoft.AzureStack.ReadinessChecker
Import-Module Microsoft.AzureStack.ReadinessChecker

$subject = "C=US,ST=Washington,L=Local,O=Mark Scholman,OU=IT"

New-Item -ItemType Directory -Path .\AzureStackCSR -ErrorAction SilentlyContinue -Force
$outputDirectory = ".\AzureStackCSR"

$regionName = 'local'
$externalFQDN = 'azurestack.external'

# App Services
New-AzsCertificateSigningRequest -certificateType AppServices -RegionName $regionName -FQDN $externalFQDN -subject $subject -OutputRequestPath $OutputDirectory

# DBAdapter
New-AzsCertificateSigningRequest -certificateType DBAdapter -RegionName $regionName -FQDN $externalFQDN -subject $subject -OutputRequestPath $OutputDirectory

# EventHubs
New-AzsCertificateSigningRequest -certificateType EventHubs -RegionName $regionName -FQDN $externalFQDN -subject $subject -OutputRequestPath $OutputDirectory

# IoTHub
New-AzsCertificateSigningRequest -certificateType IoTHub -RegionName $regionName -FQDN $externalFQDN -subject $subject -OutputRequestPath $OutputDirectory