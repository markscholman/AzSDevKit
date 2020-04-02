# Add the Azure cloud subscription environment name. 
# Supported environment names are AzureCloud, AzureChinaCloud, or AzureUSGovernment depending which Azure subscription you're using.
Add-AzureRmAccount -EnvironmentName "AzureCloud" -Tenant '<TENANTNAME / ID>' #be aware of PIM

# Register the Azure Stack resource provider in your Azure subscription
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.AzureStack

# Import the registration module that was downloaded with the GitHub tools
Import-Module .\AzureStack-Tools-master\Registration\RegisterWithAzure.psm1

# If you have multiple subscriptions, run the following command to select the one you want to use:
# Get-AzureRmSubscription -SubscriptionID "<subscription ID>" | Select-AzureRmSubscription

# Register Azure Stack
$AzureContext = Get-AzureRmContext
$CloudAdminCred = Get-Credential -UserName AZURESTACK\CloudAdmin -Message "Enter the credentials to access the privileged endpoint."
$RegistrationName = "AzSHDevKit1"
Set-AzsRegistration `
    -PrivilegedEndpointCredential $CloudAdminCred `
    -PrivilegedEndpoint AzS-ERCS01 `
    -BillingModel Development `
    -RegistrationName $RegistrationName `
    -UsageReportingEnabled:$true