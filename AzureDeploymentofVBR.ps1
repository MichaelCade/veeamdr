# Connect to Azure with a browser sign in token
Connect-AzAccount

# Set the Marketplace image
$locName="EASTUS"
$pubName="veeam"
$offerName="veeam-backup-replication"
$skuName="veeam-backup-replication-v10"
$version = "10.0.1"

# Variables for common values
$resourceGroup = "CadeTestingVBR"
$vmName = "CadeVBR"
$vmSize = "Standard_F4s_v2"
$StorageSku = "Premium_LRS"
$StorageName = "cadestorage"

Get-AzVMImage -Location $locName -PublisherName $pubName -Offer $offerName -Skus $skuName -Version $version

$agreementTerms=Get-AzMarketplaceterms -Publisher "veeam" -Product "veeam-backup-replication" -Name "10.0.1"

Set-AzMarketplaceTerms -Publisher "veeam" -Product "veeam-backup-replication" -Name "10.0.1" -Terms $agreementTerms -Accept


# Create user object
$cred = Get-Credential -Message "Enter a username and password for the virtual machine."

# Create a resource group

New-AzResourceGroup -Name $resourceGroup -Location $locname -force

# Create a subnet configuration
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name "cadesubvbr" -AddressPrefix 10.0.0.0/24

# Create a virtual network
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $locName `
  -Name CadeVBRNet -AddressPrefix 10.0.0.0/24 -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
$pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Location $locName `
  -Name "CadeVBR$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name CadeVBRSecurityGroupRuleRDP  -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 3389 -Access Allow

# Create a network security group
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $locName `
  -Name CadeVBRNetSecurityGroup -SecurityRules $nsgRuleRDP

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface -Name CadeVBRNIC -ResourceGroupName $resourceGroup -Location $locName `
  -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Create a virtual machine configuration
#vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize | `
#Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | `
#Set-AzVMSourceImage -VM $vmConfig -PublisherName $pubName -Offer $offerName -Skus $skuName -Version $version | `
#Add-AzVMNetworkInterface -Id $nic.Id

#Create a virtual machine configuration

$vmConfig = New-AzVMConfig -VMName "$vmName" -VMSize $vmSize 
$vmConfig = Set-AzVMPlan -VM $vmConfig -Publisher $pubName -Product $offerName -Name $skuName
$vmConfig = Set-AzVMOperatingSystem -Windows -VM $vmConfig -ComputerName $vmName -Credential $cred
$vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName $pubName -Offer $offerName -Skus $skuName -Version $version
$vmConfig = Add-AzVMNetworkInterface -Id $nic.Id -VM $vmConfig

# Create a virtual machine
New-AzVM -ResourceGroupName $resourceGroup -Location $locName -VM $vmConfig

# Start Script installation of Azure PowerShell requirement for adding Azure Compute Account
Set-AzVMCustomScriptExtension -ResourceGroupName $resourceGroup `
    -VMName $vmName `
    -Location $locName `
    -FileUri https://raw.githubusercontent.com/MichaelCade/veeamdr/master/AzurePowerShellInstaller.ps1 `
    -Run 'AzurePowerShellInstaller.ps1' `
    -Name DemoScriptExtension

Start-Sleep -s 15

Write-host "Your public IP address is $($pip.IpAddress)"
mstsc /v:$($pip.IpAddress)