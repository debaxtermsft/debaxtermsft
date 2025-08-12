<#
written by Derrick Baxter
10/16/24
updated 
8/7/25 params and fixed some issues, added output file

setup categories by dates to get more than just a certain date, but by ranges and expired secrets

Name      Category               ExpirationDate        KeyVaultName
----      --------               --------------        ------------
ted2      SecretExpired          12/2/2022 11:59:59 PM keyvault01
wildcard  SecretExpired          12/2/2022 11:59:59 PM KeyVault1
spncert   60-180DaySecretExpiry  1/14/2025 4:45:57 PM  KeyVault1
start     180-360DaySecretExpiry 9/12/2025 2:13:48 PM  KeyVault1
newsecret GT1YearDaySecretExpiry 1/3/2026 8:03:11 PM   KeyVault1
new21424  GT1YearDaySecretExpiry 2/15/2026 9:24:49 PM  KeyVault1

.\keyvaultsecretexpiration.ps1 -tenantid "tenantid" -outputdirectory "c:\temp\" -ExportFileType HTML -SortExportBy SubscriptionName
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

$NearExpirationSecrets = @()
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
                $secrets = Get-AzKeyVaultSecret -VaultName $rgitem.VaultName
                #$secrets
                    if ($secrets.count -eq 0) {write-host "No Secrets found, check AKV RBAC/Access Policy to get/list secrets in vault " $rgitem.VaultName " subscription " $subitem.SubscriptionId}
                    else
                        {
                            foreach($secret in $secrets)
                            {
                                if($secret.Expires) {
                                $secretExpiration = Get-Date $secret.Expires -Format yyyyMMdd
                                if($secretexpiration -gt $360Days)
                                    {
                                        $NearExpirationSecrets += New-Object PSObject -Property @{
                                                    Name           = $secret.Name;
                                                    Category       = 'GT1YearDaySecretExpiry';
                                                    KeyVaultName   = $secret.vaultname;
                                                    ExpirationDate = $secret.Expires;
                                                    Created         = $secret.created;
                                                    Updated        = $secret.Updated;
                                                    Notbefore      = $secret.NotBefore;
                                                    id             =$secret.Id;
                                                    SubscriptionName   = $subitem.Name;
                                                    SubscriptionID     = $subitem.Id;
                                                    ResourceGroupName  = $rgitem.ResourceGroupName;
                                                    ResourceID         = $rgitem.id;
                                                    Location           = $rgitem.Location
                                                }
                                    }  
                                elseif($secretExpiration -le $360Days -and $secretexpiration -gt $180Days)
                                {
                                    $NearExpirationSecrets += New-Object PSObject -Property @{
                                                Name           = $secret.Name;
                                                Category       = '180-360DaySecretExpiry';
                                                KeyVaultName   = $secret.vaultname;
                                                ExpirationDate = $secret.Expires;
                                                Created         = $secret.created;
                                                Updated        = $secret.Updated;
                                                Notbefore      = $secret.NotBefore;
                                                id             =$secret.Id;
                                                SubscriptionName   = $subitem.Name;
                                                SubscriptionID     = $subitem.Id;
                                                ResourceGroupName  = $rgitem.ResourceGroupName;
                                                ResourceID         = $rgitem.id;
                                                Location           = $rgitem.Location
                                            }
                                }  
                                elseif($secretExpiration -le $180Days -and $secretexpiration -gt $60Days)
                                {
                                    $NearExpirationSecrets += New-Object PSObject -Property @{
                                                Name           = $secret.Name;
                                                Category       = '60-180DaySecretExpiry';
                                                KeyVaultName   = $secret.vaultname;
                                                ExpirationDate = $secret.Expires;
                                                Created         = $secret.created;
                                                Updated        = $secret.Updated;
                                                Notbefore      = $secret.NotBefore;
                                                id             =$secret.Id;
                                                SubscriptionName   = $subitem.Name;
                                                SubscriptionID     = $subitem.Id;
                                                ResourceGroupName  = $rgitem.ResourceGroupName;
                                                ResourceID         = $rgitem.id;
                                                Location           = $rgitem.Location
                                            }

                                }  
                                elseif($secretExpiration -le $60Days -and $secretexpiration -gt $30Days)
                                    {
                                        $NearExpirationSecrets += New-Object PSObject -Property @{
                                                    Name           = $secret.Name;
                                                    Category       = '30-60DaySecretExpiry';
                                                    KeyVaultName   = $secret.vaultname;
                                                    ExpirationDate = $secret.Expires;
                                                    Created         = $secret.created;
                                                    Updated        = $secret.Updated;
                                                    Notbefore      = $secret.NotBefore;
                                                    id             =$secret.Id;
                                                    SubscriptionName   = $subitem.Name;
                                                    SubscriptionID     = $subitem.Id;
                                                    ResourceGroupName  = $rgitem.ResourceGroupName;
                                                    ResourceID         = $rgitem.id;
                                                    Location           = $rgitem.Location
                                                }
                
                                    }  
                                elseif($secretExpiration -le $30Days -and $secretexpiration -gt $15Days)
                                    {
                                        $NearExpirationSecrets += New-Object PSObject -Property @{
                                                    Name           = $secret.Name;
                                                    Category       = '15-30DaySecretExpiry';
                                                    KeyVaultName   = $secret.vaultname;
                                                    ExpirationDate = $secret.Expires;
                                                    Created         = $secret.created;
                                                    Updated        = $secret.Updated;
                                                    Notbefore      = $secret.NotBefore;
                                                    id             =$secret.Id;
                                                    SubscriptionName   = $subitem.Name;
                                                    SubscriptionID     = $subitem.Id;
                                                    ResourceGroupName  = $rgitem.ResourceGroupName;
                                                    ResourceID         = $rgitem.id;
                                                    Location           = $rgitem.Location
                                                }
                
                                    }
                                elseif($secretExpiration -le $15Days -and $secretexpiration -gt $7Days)
                                    {
                                        $NearExpirationSecrets += New-Object PSObject -Property @{
                                                    Name           = $secret.Name;
                                                    Category       = '7-15DaySecretExpiry';
                                                    KeyVaultName   = $secret.vaultname;
                                                    ExpirationDate = $secret.Expires;
                                                    Created         = $secret.created;
                                                    Updated        = $secret.Updated;
                                                    Notbefore      = $secret.NotBefore;
                                                    id             =$secret.Id;
                                                    SubscriptionName   = $subitem.Name;
                                                    SubscriptionID     = $subitem.Id;
                                                    ResourceGroupName  = $rgitem.ResourceGroupName;
                                                    ResourceID         = $rgitem.id;
                                                    Location           = $rgitem.Location
                                                }
                
                                    }
                                elseif($secretExpiration -le $7Days -and $secretexpiration -gt $1Days)
                                    {
                                        $NearExpirationSecrets += New-Object PSObject -Property @{
                                                    Name           = $secret.Name;
                                                    Category       = '1-7DaySecretExpiry';
                                                    KeyVaultName   = $secret.vaultname;
                                                    ExpirationDate = $secret.Expires;
                                                    Created         = $secret.created;
                                                    Updated        = $secret.Updated;
                                                    Notbefore      = $secret.NotBefore;
                                                    id             =$secret.Id;
                                                    SubscriptionName   = $subitem.Name;
                                                    SubscriptionID     = $subitem.Id;
                                                    ResourceGroupName  = $rgitem.ResourceGroupName;
                                                    ResourceID         = $rgitem.id;
                                                    Location           = $rgitem.Location
                                                }
                
                                    }                      
                                elseif($secretExpiration -lt $currentDate)
                                {
                                    $NearExpirationSecrets += New-Object PSObject -Property @{
                                                Name           = $secret.Name;
                                                Category       = 'SecretExpired';
                                                KeyVaultName   = $secret.vaultname;
                                                ExpirationDate = $secret.Expires;
                                                Created         = $secret.created;
                                                Updated        = $secret.Updated;
                                                Notbefore      = $secret.NotBefore;
                                                id             =$secret.Id;
                                                SubscriptionName   = $subitem.Name;
                                                SubscriptionID     = $subitem.Id;
                                                ResourceGroupName  = $rgitem.ResourceGroupName;
                                                ResourceID         = $rgitem.id;
                                                Location           = $rgitem.Location

                                            }

                                        }

                                    }
                                    elseif($secret.expires -eq $null) {
                                        $NearExpirationSecrets += New-Object PSObject -Property @{
                                            Name           = $secret.Name;
                                            Category       = 'Expire Not Set Or Null';
                                            KeyVaultName   = $secret.vaultname;
                                            ExpirationDate = $secret.Expires;
                                            Created         = $secret.created;
                                            Updated        = $secret.Updated;
                                            Notbefore      = $secret.NotBefore;
                                            id             =$secret.Id;
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
$NearExpirationSecrets | Sort-Object  $SortExportBy  | ft -autosize

$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"

if($ExportFileType -eq "CSV")
{
$outputfile = $Outputdirectory+"secretexport_"+$tdy+".csv"
$NearExpirationSecrets | Select-Object KeyvaultName, Name, Category, Created, ExpirationDate, Notbefore, Updated, id, SubscriptionName, SubscriptionID, ResourceGroupName, Location, ResourceID| Sort-Object $SortExportBy| export-csv -Path $outputfile -NoTypeInformation -Encoding utf8
}
else
{
$htmlfile = $Outputdirectory+"secretexport_"+$tdy+".html"

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

#$htmlContent = $NearExpirationSecrets | Select-Object KeyvaultName, Name, Category, Created, ExpirationDate, Notbefore, Updated, id | Sort-Object $SortExportBy | ConvertTo-Html -Title "Key Vault Expiration Secret Export" -As "Table"
$htmlContent = $NearExpirationSecrets | Select-Object KeyvaultName, Name, Category, Created, ExpirationDate, Notbefore, Updated, id, SubscriptionName, SubscriptionID, ResourceGroupName, Location, ResourceID | Sort-Object $SortExportBy | ConvertTo-Html -Title "Key Vault Expiration Secret Export" -As "Table"
$htmlContent = $htmlContent -replace "</head>", "$cssStyle`n</head>"
$htmlContent | Out-File $htmlfile
}
