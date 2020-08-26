#This script will automate the configuration steps of adding the following steps
#Add Azure Compute Account
#Add Azure Storage Account 
#Add Capacity Tier (Microsoft Azure Blob Storage) Repository 
#Import backups from Capacity Tier Repository 
#This will then enable you to perform Direct Restore to Azure the image based backups you require. 

Add-PSSnapin VeeamPSSnapin

#Connects to Veeam backup server.
Connect-VBRServer -server "localhost"

#Add Azure Compute Account

#Need to think of a better way to run this as this will close down PowerShell when installing
msiexec.exe /I "C:\Program Files\Veeam\Backup and Replication\Console\azure-powershell.5.1.1.msi"

Add-VBRAzureAccount -Region Global

#Add Azure Storage Account 

$accesskey = "ADD AZURE ACCESS KEY"
 
$blob1 = Add-VBRAzureBlobAccount -Name "AZUREBLOBACCOUT" -SharedKey $accesskey

#Add Capacity Tier (Microsoft Azure Blob Storage) Repository 

$account = Get-VBRAzureBlobAccount -Name "AZUREBLOBACCOUNT"
 
$connect = Connect-VBRAzureBlobService -Account $account -RegionType Global -ServiceType CapacityTier

$container = Get-VBRAzureBlobContainer -Connection $connect | where {$_.name -eq 'AZURECONTAINER'}

$folder = Get-VBRAzureBlobFolder -Container $container -Connection $connect

#The name needs to be exactly the same as you find in your production Veeam Backup & Replication server
$repositoryname = "REPOSITORYNAME"

Add-VBRAzureBlobRepository -AzureBlobFolder $folder -Connection $connect -Name $repositoryname

#Import backups from Capacity Tier Repository 

$repository = Get-VBRObjectStorageRepository -Name $repositoryname

Mount-VBRObjectStorageRepository -Repository $repository 
Rescan-VBREntity -AllRepositories

#if you have used an encryption key then configure this section 

#$key = Get-VBREncryptionKey -Description "Object Storage Key"
#Mount-VBRObjectStorageRepository -Repository $repository -EncryptionKey $key

 #This next section will enable you to automate the Direct Restore to Microsoft Azure 

$restorepoint = Get-VBRRestorePoint -Name "VMBACKUPNAME" | Sort-Object $_.creationtime -Descending | Select -First 1 

$account = Get-VBRAzureAccount -Type ResourceManager -Name "AZURECOMPUTEACCOUNT"

$subscription = Get-VBRAzureSubscription -Account $account -name "SUBSCRIPTIONNAME"

$storageaccount = Get-VBRAzureStorageAccount -Subscription $subscription -Name "STORAGEACCOUNTFORRESTOREDMACHINE"

$location = Get-VBRAzureLocation -Subscription $subscription -Name "REGION"

$vmsize = Get-VBRAzureVMSize -Subscription $subscription -Location $location -Name Basic_A0

$network = Get-VBRAzureVirtualNetwork -Subscription $subscription -Name "AZURENETWORK"

$subnet = Get-VBRAzureVirtualNetworkSubnet -Network $network -Name "SUBNET"

$resourcegroup = Get-VBRAzureResourceGroup -Subscription $subscription -Name "AZURERESOURCEGROUP"

$RestoredVMName1 = "NAMEOFRESTOREDMACHINEINAZURE"


Start-VBRVMRestoreToAzure -RestorePoint $restorepoint -Subscription $subscription -StorageAccount $storageaccount -VmSize $vmsize -VirtualNetwork $network -VirtualSubnet $subnet -ResourceGroup $resourcegroup -VmName $RestoredVMName1 -Reason "Automated DR to the Cloud Testing"





