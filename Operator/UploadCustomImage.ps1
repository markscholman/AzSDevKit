
$rg = New-AzureRmResourceGroup -Name 'customimages.corp' -Location 'corp'
$storageAcct = New-AzureRmStorageAccount -Location 'corp' -Name 'customimagestore' -SkuName 'Standard_LRS' -ResourceGroupName $rg.ResourceGroupName
New-AzureStorageContainer -Name 'upload' -Context $storageAcct.Context

Add-AzureRmVhd -Destination "https://customimagestore.blob.local.azurestack.external/upload/win2019std.vhd" -LocalFilePath "X:\win2019std.vhd" -ResourceGroupName $rg.ResourceGroupName

Add-AzsPlatformimage -publisher "MicrosoftWindowsServer" `
   -offer "WindowsServer" `
   -sku "2019-Standard" `
   -version "2019.127.20200409" `
   -OSType "Windows" `
   -OSUri "https://customimagestore.blob.local.azurestack.external/upload/win2019std.vhd"


AzureGallery.exe package –manifestfile "C:\CustomImageUpload\CustomVMs\WindowsServer2019.Standard.1.0.0\manifest.json" –o 'c:\Temp'

Add-AzsGalleryItem -GalleryItemUri 'https://customimagestore.blob.local.azurestack.external/upload/Microsoft.WindowsServer2019Standard-ARM.1.0.0.azpkg' –Verbose
Remove-AzsGalleryItem -Name Microsoft.WindowsServer2019Standard-ARM.1.0.0 -Verbose
