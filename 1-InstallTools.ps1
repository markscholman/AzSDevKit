Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
# Install the AzureRM.BootStrapper module. Select Yes when prompted to install NuGet
Install-Module -Name AzureRM.BootStrapper -Scope CurrentUser -Force

# Install and import the API Version Profile required by Azure Stack Hub into the current PowerShell session.
Use-AzureRmProfile -Profile 2019-03-01-hybrid -Force -Scope CurrentUser
Install-Module -Name AzureStack -RequiredVersion 1.8.1 -Scope CurrentUser -Force

# Download the tools archive.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
invoke-webrequest -Uri https://github.com/Azure/AzureStack-Tools/archive/master.zip -OutFile master.zip
Expand-Archive master.zip -DestinationPath . -Force
rm .\master.zip

Invoke-WebRequest -Uri https://github.com/Azure/aks-engine/releases/download/v0.43.3/aks-engine-v0.43.3-windows-amd64.zip -OutFile aks-engine-v0.43.3-windows-amd64.zip
Expand-Archive -Path .\aks-engine-v0.43.3-windows-amd64.zip
rm .\aks-engine-v0.43.3-windows-amd64.zip

Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process AzureCLI.msi /qb
rm .\AzureCLI.msi

Invoke-WebRequest -Uri https://aka.ms/win32-x64-user-stable -OutFile VSCodeUserSetup.exe 
.\VSCodeUserSetup.exe /quiet
rm .\VSCodeUserSetup.exe

Invoke-WebRequest -Uri https://github.com/git-for-windows/git/releases/download/v2.26.0.windows.1/Git-2.26.0-64-bit.exe -OutFile Git-2.26.0-64-bit.exe
.\Git-2.26.0-64-bit.exe
rm .\Git-2.26.0-64-bit.exe

Invoke-WebRequest -Uri https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/windows/amd64/kubectl.exe -OutFile kubectl.exe
New-Item -ItemType Directory -Path $env:APPDATA\kubectl
Move-Item .\kubectl.exe $env:APPDATA\kubectl\

#Configure Azure CLI Cert trust for Azure Stack ASDK

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