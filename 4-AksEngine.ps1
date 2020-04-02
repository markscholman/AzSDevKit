#RUNAS ADMINISTRATOR At least till line 45 :-)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
invoke-webrequest -Uri https://github.com/Azure/aks-engine/releases/download/v0.43.3/aks-engine-v0.43.3-windows-amd64.zip -OutFile aks-engine-v0.43.3-windows-amd64.zip
Expand-Archive -Path .\aks-engine-v0.43.3-windows-amd64.zip
rm .\aks-engine-v0.43.3-windows-amd64.zip

Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process AzureCLI.msi /qb
rm .\AzureCLI.msi

$python = Get-Command -CommandType Application -Name  'C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\python.exe' -ErrorAction SilentlyContinue
$certPath = & $python -c "import certifi; print(certifi.where())"
$rootCert = Get-ChildItem Cert:\LocalMachine\My\ | Where-Object {$_.Subject -eq 'CN=AzureStackSelfSignedRootCert'}

Export-Certificate -Type CERT -FilePath root.cer -Cert $rootCert
Write-Host "Converting certificate to PEM format"
certutil -encode root.cer root.pem

$pemFile = '.\root.pem'
$root = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$root.Import($pemFile)

Write-Host "Extracting required information from the cert file"
$md5Hash    = (Get-FileHash -Path $pemFile -Algorithm MD5).Hash.ToLower()
$sha1Hash   = (Get-FileHash -Path $pemFile -Algorithm SHA1).Hash.ToLower()
$sha256Hash = (Get-FileHash -Path $pemFile -Algorithm SHA256).Hash.ToLower()

$issuerEntry  = [string]::Format("# Issuer: {0}", $root.Issuer)
$subjectEntry = [string]::Format("# Subject: {0}", $root.Subject)
$labelEntry   = [string]::Format("# Label: {0}", $root.Subject.Split('=')[-1])
$serialEntry  = [string]::Format("# Serial: {0}", $root.GetSerialNumberString().ToLower())
$md5Entry     = [string]::Format("# MD5 Fingerprint: {0}", $md5Hash)
$sha1Entry    = [string]::Format("# SHA1 Fingerprint: {0}", $sha1Hash)
$sha256Entry  = [string]::Format("# SHA256 Fingerprint: {0}", $sha256Hash)
$certText = (Get-Content -Path $pemFile -Raw).ToString().Replace("`r`n","`n")

$rootCertEntry = "`n" + $issuerEntry + "`n" + $subjectEntry + "`n" + $labelEntry + "`n" + `
$serialEntry + "`n" + $md5Entry + "`n" + $sha1Entry + "`n" + $sha256Entry + "`n" + $certText

Write-Host "Adding the certificate content to Python Cert store"
Add-Content $certPath $rootCertEntry

Write-Host "Python Cert store was updated to allow the Azure Stack Hub CA root certificate"

$aks = Get-Command -CommandType Application -Name ".\aks-engine-v0.43.3-windows-amd64\aks-engine-v0.43.3-windows-amd64\aks-engine.exe" -ErrorAction SilentlyContinue
& $aks version
if ($null -eq $aks) {
    throw 'aks-engine is not installed or not available on PATH'
}
$az = Get-Command -CommandType Application -Name az -ErrorAction SilentlyContinue
if ($null -eq $az) {
    throw 'az cli is not installed or not available on PATH'
}

ssh-keygen -t rsa -C "azurestackadmin@azurestack.external" 
$sshPublicKey = cat $env:USERPROFILE/.ssh/id_rsa.pub
$kubeAzS = Get-Content ./4-kubernetes-azurestack.json | ConvertFrom-Json
$kubeAzS.properties.linuxProfile.ssh.publicKeys[0].keyData = $sshPublicKey
$kubeAzS | ConvertTo-Json -Depth 99 | Out-File ./kubernetes-azurestack.json

& $az cloud register -n AzureStack --endpoint-resource-manager "https://management.local.azurestack.external" --suffix-storage-endpoint "local.azurestack.external" --suffix-keyvault-dns ".vault.local.azurestack.external"
& $az cloud set -n AzureStack

& $az cloud update --profile 2019-03-01-hybrid
& $az login

& $aks deploy `
    --azure-env 'AzureStackCloud' `
    --location 'local' `
    --resource-group 'kube-rg' `
    --api-model 'kubernetes-azurestack.json' `
    --output-directory 'kube-rg' `
    --client-id '' `
    --client-secret '' `
    --subscription-id '' -f

