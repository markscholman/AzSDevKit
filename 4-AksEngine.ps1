

$kubectl = Get-Command -CommandType Application -Name $env:APPDATA\kubectl\kubectl.exe -ErrorAction SilentlyContinue
#& $kubectl version
if ($null -eq $kubectl) {
    throw 'kubectl is not installed or not available on PATH'
}

$aks = Get-Command -CommandType Application -Name ".\aks-engine-v0.43.3-windows-amd64\aks-engine-v0.43.3-windows-amd64\aks-engine.exe" -ErrorAction SilentlyContinue
#& $aks version
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

