<#
written by Derrick Baxter
10/16/24
updated 
8/7/25 params and fixed some issues, added output file

setup categories by dates to get more than just a certain date, but by ranges and expired certificates

Name      Category               ExpirationDate        KeyVaultName
----      --------               --------------        ------------
ted2      certificateExpired          12/2/2022 11:59:59 PM keyvault01
wildcard  certificateExpired          12/2/2022 11:59:59 PM KeyVault1
spncert   60-180DaycertificateExpiry  1/14/2025 4:45:57 PM  KeyVault1
start     180-360DaycertificateExpiry 9/12/2025 2:13:48 PM  KeyVault1
newcertificate GT1YearDaycertificateExpiry 1/3/2026 8:03:11 PM   KeyVault1
new21424  GT1YearDaycertificateExpiry 2/15/2026 9:24:49 PM  KeyVault1

.\keyvaultcertificateexpiration.ps1 -tenantid "tenantid" -outputdirectory "c:\temp\" -Outputdirectory c:\temp\ -ExportFileType HTML -SortExportBy SubscriptionName
make sure to add the trailing \ on the path 
SortExportBy Options "SubscriptionName", "ResourceGroupName", "Location", "Category" , "ExpirationDate"

#>#>

param([parameter(Position=0,mandatory)][string]$tenantId,
[parameter (Position=5,mandatory)][validateset("SubscriptionName", "ResourceGroupName", "Location", "Category" , "ExpirationDate")] [string]$SortExportBy,
[parameter (Position=5,mandatory)][validateset("HTML", "CSV")] [string]$ExportFileType,
[parameter(Position=1,mandatory)] [string]$Outputdirectory)

try {
    Get-AzSubscription -TenantId $tenantId -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
}
catch {
    connect-azaccount -tenantid $tenantId
}

$NearExpirationcertificates = @()
$subscriptions = Get-AzSubscription -TenantId $tenantId

$1Days = Get-Date (Get-Date).AddDays(1) -Format yyyyMMdd
$7Days = Get-Date (Get-Date).AddDays(7) -Format yyyyMMdd
$15Days = Get-Date (Get-Date).AddDays(15) -Format yyyyMMdd
$30Days = Get-Date (Get-Date).AddDays(30) -Format yyyyMMdd
$60Days = Get-Date (Get-Date).AddDays(60) -Format yyyyMMdd
$180Days = Get-Date (Get-Date).AddDays(180) -Format yyyyMMdd
$360days = Get-Date (Get-Date).AddDays(360) -Format yyyyMMdd
$3600day = Get-Date (Get-Date).AddDays(3600) -Format yyyyMMdd
$CurrentDate = Get-Date -Format yyyyMMdd

foreach ($subitem in $subscriptions)
{
    Set-AzContext -Subscription $subitem.id -Tenant $tenantId
    $kvnames = get-azkeyvault 

    if ($kvnames.count -eq 0){
        write-host "No key vault in subscription found, check AKV RBAC/access policy permissions" 
    }
    else {


            $kvnames = get-azkeyvault

            foreach($rgitem in $kvnames)
            {
                $certificates = Get-AzKeyVaultcertificate -VaultName $rgitem.VaultName
                #$certificates
                    if ($certificates.count -eq 0) {write-host "No certificates found, check AKV RBAC/Access Policy to get/list certificates in vault " $rgitem.VaultName " subscription " $subitem.SubscriptionId}
                    else
                        {
                            foreach($certificate in $certificates)
                            {
                                if($certificate.Expires) {
                                $certificateExpiration = Get-Date $certificate.Expires -Format yyyyMMdd
                                if($certificateexpiration -gt $360Days)
                                    {
                                        $NearExpirationcertificates += New-Object PSObject -Property @{
                                                    Name           = $certificate.Name;
                                                    Category       = 'GT1YearDaycertificateExpiry';
                                                    KeyVaultName   = $certificate.vaultname;
                                                    ExpirationDate = $certificate.Expires;
                                                    Created         = $certificate.created;
                                                    Updated        = $certificate.Updated;
                                                    Notbefore      = $certificate.NotBefore;
                                                    id             =$certificate.Id;
                                                    SubscriptionName   = $subitem.Name;
                                                    SubscriptionID     = $subitem.Id;
                                                    ResourceGroupName  = $rgitem.ResourceGroupName;
                                                    ResourceID         = $rgitem.id;
                                                    Location           = $rgitem.Location
                                                }
                                    }  
                                elseif($certificateExpiration -le $360Days -and $certificateexpiration -gt $180Days)
                                {
                                    $NearExpirationcertificates += New-Object PSObject -Property @{
                                                Name           = $certificate.Name;
                                                Category       = '180-360DaycertificateExpiry';
                                                KeyVaultName   = $certificate.vaultname;
                                                ExpirationDate = $certificate.Expires;
                                                Created         = $certificate.created;
                                                Updated        = $certificate.Updated;
                                                Notbefore      = $certificate.NotBefore;
                                                id             =$certificate.Id;
                                                SubscriptionName   = $subitem.Name;
                                                SubscriptionID     = $subitem.Id;
                                                ResourceGroupName  = $rgitem.ResourceGroupName;
                                                ResourceID         = $rgitem.id;
                                                Location           = $rgitem.Location
                                            }
                                }  
                                elseif($certificateExpiration -le $180Days -and $certificateexpiration -gt $60Days)
                                {
                                    $NearExpirationcertificates += New-Object PSObject -Property @{
                                                Name           = $certificate.Name;
                                                Category       = '60-180DaycertificateExpiry';
                                                KeyVaultName   = $certificate.vaultname;
                                                ExpirationDate = $certificate.Expires;
                                                Created         = $certificate.created;
                                                Updated        = $certificate.Updated;
                                                Notbefore      = $certificate.NotBefore;
                                                id             =$certificate.Id;
                                                SubscriptionName   = $subitem.Name;
                                                SubscriptionID     = $subitem.Id;
                                                ResourceGroupName  = $rgitem.ResourceGroupName;
                                                ResourceID         = $rgitem.id;
                                                Location           = $rgitem.Location
                                            }

                                }  
                                elseif($certificateExpiration -le $60Days -and $certificateexpiration -gt $30Days)
                                    {
                                        $NearExpirationcertificates += New-Object PSObject -Property @{
                                                    Name           = $certificate.Name;
                                                    Category       = '30-60DaycertificateExpiry';
                                                    KeyVaultName   = $certificate.vaultname;
                                                    ExpirationDate = $certificate.Expires;
                                                    Created         = $certificate.created;
                                                    Updated        = $certificate.Updated;
                                                    Notbefore      = $certificate.NotBefore;
                                                    id             =$certificate.Id;
                                                    SubscriptionName   = $subitem.Name;
                                                    SubscriptionID     = $subitem.Id;
                                                    ResourceGroupName  = $rgitem.ResourceGroupName;
                                                    ResourceID         = $rgitem.id;
                                                    Location           = $rgitem.Location
                                                }
                
                                    }  
                                elseif($certificateExpiration -le $30Days -and $certificateexpiration -gt $15Days)
                                    {
                                        $NearExpirationcertificates += New-Object PSObject -Property @{
                                                    Name           = $certificate.Name;
                                                    Category       = '15-30DaycertificateExpiry';
                                                    KeyVaultName   = $certificate.vaultname;
                                                    ExpirationDate = $certificate.Expires;
                                                    Created         = $certificate.created;
                                                    Updated        = $certificate.Updated;
                                                    Notbefore      = $certificate.NotBefore;
                                                    id             =$certificate.Id;
                                                    SubscriptionName   = $subitem.Name;
                                                    SubscriptionID     = $subitem.Id;
                                                    ResourceGroupName  = $rgitem.ResourceGroupName;
                                                    ResourceID         = $rgitem.id;
                                                    Location           = $rgitem.Location
                                                }
                
                                    }
                                elseif($certificateExpiration -le $15Days -and $certificateexpiration -gt $7Days)
                                    {
                                        $NearExpirationcertificates += New-Object PSObject -Property @{
                                                    Name           = $certificate.Name;
                                                    Category       = '7-15DaycertificateExpiry';
                                                    KeyVaultName   = $certificate.vaultname;
                                                    ExpirationDate = $certificate.Expires;
                                                    Created         = $certificate.created;
                                                    Updated        = $certificate.Updated;
                                                    Notbefore      = $certificate.NotBefore;
                                                    id             =$certificate.Id;
                                                    SubscriptionName   = $subitem.Name;
                                                    SubscriptionID     = $subitem.Id;
                                                    ResourceGroupName  = $rgitem.ResourceGroupName;
                                                    ResourceID         = $rgitem.id;
                                                    Location           = $rgitem.Location
                                                }
                
                                    }
                                elseif($certificateExpiration -le $7Days -and $certificateexpiration -gt $1Days)
                                    {
                                        $NearExpirationcertificates += New-Object PSObject -Property @{
                                                    Name           = $certificate.Name;
                                                    Category       = '1-7DaycertificateExpiry';
                                                    KeyVaultName   = $certificate.vaultname;
                                                    ExpirationDate = $certificate.Expires;
                                                    Created         = $certificate.created;
                                                    Updated        = $certificate.Updated;
                                                    Notbefore      = $certificate.NotBefore;
                                                    id             =$certificate.Id;
                                                    SubscriptionName   = $subitem.Name;
                                                    SubscriptionID     = $subitem.Id;
                                                    ResourceGroupName  = $rgitem.ResourceGroupName;
                                                    ResourceID         = $rgitem.id;
                                                    Location           = $rgitem.Location
                                                }
                
                                    }                      
                                elseif($certificateExpiration -lt $currentDate)
                                {
                                    $NearExpirationcertificates += New-Object PSObject -Property @{
                                                Name           = $certificate.Name;
                                                Category       = 'certificateExpired';
                                                KeyVaultName   = $certificate.vaultname;
                                                ExpirationDate = $certificate.Expires;
                                                Created         = $certificate.created;
                                                Updated        = $certificate.Updated;
                                                Notbefore      = $certificate.NotBefore;
                                                id             =$certificate.Id;
                                                SubscriptionName   = $subitem.Name;
                                                SubscriptionID     = $subitem.Id;
                                                ResourceGroupName  = $rgitem.ResourceGroupName;
                                                ResourceID         = $rgitem.id;
                                                Location           = $rgitem.Location

                                            }

                                        }

                                    }
                                    elseif($certificate.expires -eq $null) {
                                        $NearExpirationcertificates += New-Object PSObject -Property @{
                                            Name           = $certificate.Name;
                                            Category       = 'Expire Not Set Or Null';
                                            KeyVaultName   = $certificate.vaultname;
                                            ExpirationDate = $certificate.Expires;
                                            Created         = $certificate.created;
                                            Updated        = $certificate.Updated;
                                            Notbefore      = $certificate.NotBefore;
                                            id             =$certificate.Id;
                                            SubscriptionName   = $subitem.Name;
                                            SubscriptionID     = $subitem.Id;
                                            ResourceGroupName  = $rgitem.ResourceGroupName;
                                            ResourceID         = $rgitem.id;
                                            Location           = $rgitem.Location

                                        }
                                    }
                            }
                        }
            }
        }
}
$NearExpirationcertificates | Sort-Object  $SortExportBy  | ft -autosize

$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"

if($ExportFileType -eq "CSV")
{
$outputfile = $Outputdirectory+"certificateexport_"+$tdy+".csv"
$NearExpirationcertificates | Select-Object KeyvaultName, Name, Category, Created, ExpirationDate, Notbefore, Updated, id, SubscriptionName, SubscriptionID, ResourceGroupName, Location, ResourceID| Sort-Object $SortExportBy| export-csv -Path $outputfile -NoTypeInformation -Encoding utf8
}
else
{
$htmlfile = $Outputdirectory+"certificateexport_"+$tdy+".html"

$cssStyle = @"
<style>
table {
    width: 100%;
    border-collapse: collapse;
}
th, td {
    border: 1px solid #dddddd;
    text-align: left;
    padding: 8px;
}
tr:nth-child(even) {
    background-color: #f2f2f2;
}
th {
    background-color:rgb(32, 156, 228);
    color: white;
}
</style>
"@

$htmlContent = $NearExpirationcertificates | Select-Object KeyvaultName, Name, Category, Created, ExpirationDate, Notbefore, Updated, id, SubscriptionName, SubscriptionID, ResourceGroupName, Location, ResourceID | Sort-Object $SortExportBy | ConvertTo-Html -Title "Key Vault Expiration certificate Export" -As "Table"
$htmlContent = $htmlContent -replace "</head>", "$cssStyle`n</head>"
$htmlContent | Out-File $htmlfile
}
