<#
import-module keyvaultobjectexporter.psm1
commands

ExportFileType Options HTML or CSV
SortExportBy Options "SubscriptionName", "ResourceGroupName", "Location", "Category" , "ExpirationDate"

Exporting Keys
HTML Output
export-akvkey -tenantId "tenantID" -Outputdirectory c:\temp\ -ExportFileType HTML -SortExportBy ResourceGroupName
CSV Output
export-akvkey -tenantId "tenantID" -Outputdirectory c:\temp\ -ExportFileType CSV -SortExportBy ResourceGroupName

Exporting Certificates
HTML Output
export-akvcertificate -tenantId "tenantID" -Outputdirectory c:\temp\ -ExportFileType HTML -SortExportBy ResourceGroupName
CSV Output
export-akvcertificate -tenantId "tenantID" -Outputdirectory c:\temp\ -ExportFileType HTML -SortExportBy ResourceGroupName

Exporting Secrets
HTML Output
export-akvsecret -tenantId "tenantID" -Outputdirectory c:\temp\ -ExportFileType HTML -SortExportBy ResourceGroupName
CSV Output
export-akvsecret -tenantId "tenantID" -Outputdirectory c:\temp\ -ExportFileType HTML -SortExportBy ResourceGroupName

#>
function export-akvkey 
{

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

$NearExpirationkeys = @()
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
                $keys = Get-AzKeyVaultkey -VaultName $rgitem.VaultName
                #$keys
                    if ($keys.count -eq 0) {write-host "No keys found, check AKV RBAC/Access Policy to get/list keys in vault " $rgitem.VaultName " subscription " $subitem.SubscriptionId}
                    else
                        {
                            foreach($key in $keys)
                            {
                                if($key.Expires) {
                                $keyExpiration = Get-Date $key.Expires -Format yyyyMMdd
                                if($keyexpiration -gt $360Days)
                                    {
                                        $NearExpirationkeys += New-Object PSObject -Property @{
                                                    Name           = $key.Name;
                                                    Category       = 'GT1YearDaykeyExpiry';
                                                    KeyVaultName   = $key.vaultname;
                                                    ExpirationDate = $key.Expires;
                                                    Created         = $key.created;
                                                    Updated        = $key.Updated;
                                                    Notbefore      = $key.NotBefore;
                                                    id             =$key.Id;
                                                    SubscriptionName   = $subitem.Name;
                                                    SubscriptionID     = $subitem.Id;
                                                    ResourceGroupName  = $rgitem.ResourceGroupName;
                                                    ResourceID         = $rgitem.id;
                                                    Location           = $rgitem.Location
                                                }
                                    }  
                                elseif($keyExpiration -le $360Days -and $keyexpiration -gt $180Days)
                                {
                                    $NearExpirationkeys += New-Object PSObject -Property @{
                                                Name           = $key.Name;
                                                Category       = '180-360DaykeyExpiry';
                                                KeyVaultName   = $key.vaultname;
                                                ExpirationDate = $key.Expires;
                                                Created         = $key.created;
                                                Updated        = $key.Updated;
                                                Notbefore      = $key.NotBefore;
                                                id             =$key.Id;
                                                SubscriptionName   = $subitem.Name;
                                                SubscriptionID     = $subitem.Id;
                                                ResourceGroupName  = $rgitem.ResourceGroupName;
                                                ResourceID         = $rgitem.id;
                                                Location           = $rgitem.Location
                                            }
                                }  
                                elseif($keyExpiration -le $180Days -and $keyexpiration -gt $60Days)
                                {
                                    $NearExpirationkeys += New-Object PSObject -Property @{
                                                Name           = $key.Name;
                                                Category       = '60-180DaykeyExpiry';
                                                KeyVaultName   = $key.vaultname;
                                                ExpirationDate = $key.Expires;
                                                Created         = $key.created;
                                                Updated        = $key.Updated;
                                                Notbefore      = $key.NotBefore;
                                                id             =$key.Id;
                                                SubscriptionName   = $subitem.Name;
                                                SubscriptionID     = $subitem.Id;
                                                ResourceGroupName  = $rgitem.ResourceGroupName;
                                                ResourceID         = $rgitem.id;
                                                Location           = $rgitem.Location
                                            }

                                }  
                                elseif($keyExpiration -le $60Days -and $keyexpiration -gt $30Days)
                                    {
                                        $NearExpirationkeys += New-Object PSObject -Property @{
                                                    Name           = $key.Name;
                                                    Category       = '30-60DaykeyExpiry';
                                                    KeyVaultName   = $key.vaultname;
                                                    ExpirationDate = $key.Expires;
                                                    Created         = $key.created;
                                                    Updated        = $key.Updated;
                                                    Notbefore      = $key.NotBefore;
                                                    id             =$key.Id;
                                                    SubscriptionName   = $subitem.Name;
                                                    SubscriptionID     = $subitem.Id;
                                                    ResourceGroupName  = $rgitem.ResourceGroupName;
                                                    ResourceID         = $rgitem.id;
                                                    Location           = $rgitem.Location
                                                }
                
                                    }  
                                elseif($keyExpiration -le $30Days -and $keyexpiration -gt $15Days)
                                    {
                                        $NearExpirationkeys += New-Object PSObject -Property @{
                                                    Name           = $key.Name;
                                                    Category       = '15-30DaykeyExpiry';
                                                    KeyVaultName   = $key.vaultname;
                                                    ExpirationDate = $key.Expires;
                                                    Created         = $key.created;
                                                    Updated        = $key.Updated;
                                                    Notbefore      = $key.NotBefore;
                                                    id             =$key.Id;
                                                    SubscriptionName   = $subitem.Name;
                                                    SubscriptionID     = $subitem.Id;
                                                    ResourceGroupName  = $rgitem.ResourceGroupName;
                                                    ResourceID         = $rgitem.id;
                                                    Location           = $rgitem.Location
                                                }
                
                                    }
                                elseif($keyExpiration -le $15Days -and $keyexpiration -gt $7Days)
                                    {
                                        $NearExpirationkeys += New-Object PSObject -Property @{
                                                    Name           = $key.Name;
                                                    Category       = '7-15DaykeyExpiry';
                                                    KeyVaultName   = $key.vaultname;
                                                    ExpirationDate = $key.Expires;
                                                    Created         = $key.created;
                                                    Updated        = $key.Updated;
                                                    Notbefore      = $key.NotBefore;
                                                    id             =$key.Id;
                                                    SubscriptionName   = $subitem.Name;
                                                    SubscriptionID     = $subitem.Id;
                                                    ResourceGroupName  = $rgitem.ResourceGroupName;
                                                    ResourceID         = $rgitem.id;
                                                    Location           = $rgitem.Location
                                                }
                
                                    }
                                elseif($keyExpiration -le $7Days -and $keyexpiration -gt $1Days)
                                    {
                                        $NearExpirationkeys += New-Object PSObject -Property @{
                                                    Name           = $key.Name;
                                                    Category       = '1-7DaykeyExpiry';
                                                    KeyVaultName   = $key.vaultname;
                                                    ExpirationDate = $key.Expires;
                                                    Created         = $key.created;
                                                    Updated        = $key.Updated;
                                                    Notbefore      = $key.NotBefore;
                                                    id             =$key.Id;
                                                    SubscriptionName   = $subitem.Name;
                                                    SubscriptionID     = $subitem.Id;
                                                    ResourceGroupName  = $rgitem.ResourceGroupName;
                                                    ResourceID         = $rgitem.id;
                                                    Location           = $rgitem.Location
                                                }
                
                                    }                      
                                elseif($keyExpiration -lt $currentDate)
                                {
                                    $NearExpirationkeys += New-Object PSObject -Property @{
                                                Name           = $key.Name;
                                                Category       = 'keyExpired';
                                                KeyVaultName   = $key.vaultname;
                                                ExpirationDate = $key.Expires;
                                                Created         = $key.created;
                                                Updated        = $key.Updated;
                                                Notbefore      = $key.NotBefore;
                                                id             =$key.Id;
                                                SubscriptionName   = $subitem.Name;
                                                SubscriptionID     = $subitem.Id;
                                                ResourceGroupName  = $rgitem.ResourceGroupName;
                                                ResourceID         = $rgitem.id;
                                                Location           = $rgitem.Location

                                            }

                                        }

                                    }
                                    elseif($key.expires -eq $null) {
                                        $NearExpirationkeys += New-Object PSObject -Property @{
                                            Name           = $key.Name;
                                            Category       = 'Expire Not Set Or Null';
                                            KeyVaultName   = $key.vaultname;
                                            ExpirationDate = $key.Expires;
                                            Created         = $key.created;
                                            Updated        = $key.Updated;
                                            Notbefore      = $key.NotBefore;
                                            id             =$key.Id;
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
$NearExpirationkeys | Sort-Object  $SortExportBy  | ft -autosize

$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"

if($ExportFileType -eq "CSV")
{
$outputfile = $Outputdirectory+"keyexport_"+$tdy+".csv"
$NearExpirationkeys | Select-Object KeyvaultName, Name, Category, Created, ExpirationDate, Notbefore, Updated, id, SubscriptionName, SubscriptionID, ResourceGroupName, Location, ResourceID| Sort-Object $SortExportBy| export-csv -Path $outputfile -NoTypeInformation -Encoding utf8
}
else
{
$htmlfile = $Outputdirectory+"keyexport_"+$tdy+".html"

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

#$htmlContent = $NearExpirationkeys | Select-Object KeyvaultName, Name, Category, Created, ExpirationDate, Notbefore, Updated, id | Sort-Object $SortExportBy | ConvertTo-Html -Title "Key Vault Expiration key Export" -As "Table"
$htmlContent = $NearExpirationkeys | Select-Object KeyvaultName, Name, Category, Created, ExpirationDate, Notbefore, Updated, id, SubscriptionName, SubscriptionID, ResourceGroupName, Location, ResourceID | Sort-Object $SortExportBy | ConvertTo-Html -Title "Key Vault Expiration key Export" -As "Table"
$htmlContent = $htmlContent -replace "</head>", "$cssStyle`n</head>"
$htmlContent | Out-File $htmlfile
}

}
function export-akvsecret 
{
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

}
function export-akvcertificate
{
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

}



Export-ModuleMember -Function export-akvkey 
Export-ModuleMember -function export-akvsecret
Export-ModuleMember -function export-akvcertificate
