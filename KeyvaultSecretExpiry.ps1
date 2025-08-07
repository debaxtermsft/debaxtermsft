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

.\keyvaultsecretexpiration.ps1 -tenantid "tenantid" -outputdirectory "c:\temp\"
make sure to add the trailing \ on the path 

#>#>

param([parameter(Position=0,mandatory)][string]$tenantId,
[parameter(Position=1,mandatory)] [string]$Outputdirectory)


connect-azaccount -tenantid $tenantId
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
        write-host "no kv" 
    }
    else {


            $kvnames = get-azkeyvault

            foreach($rgitem in $kvnames)
            {
            #$KeyVault = Get-AzKeyVault -ResourceGroupName $rgitem.resourcegroupname -VaultName $rgitem.vaultname
                #foreach ($kvitem in $keyvault)
                    #{
                        $secrets = Get-AzKeyVaultSecret -VaultName $rgitem.VaultName
                        #$secrets



                            foreach($secret in $secrets){
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
                                                    id             =$secret.Id
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
                                                id             =$secret.Id
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
                                                id             =$secret.Id
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
                                                    id             =$secret.Id
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
                                                    id             =$secret.Id
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
                                                    id             =$secret.Id
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
                                                    id             =$secret.Id
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
                                                id             =$secret.Id

                                            }

                                }

                            }
                            elseif($secret.expires -eq $null) {
                                $NearExpirationSecrets += New-Object PSObject -Property @{
                                    Name           = $secret.Name;
                                    Category       = 'SecretNotSetOrNull';
                                    KeyVaultName   = $secret.vaultname;
                                    ExpirationDate = $secret.Expires;
                                    Created         = $secret.created;
                                    Updated        = $secret.Updated;
                                    Notbefore      = $secret.NotBefore;
                                    id             =$secret.Id

                                }
                            }
                    }
                #}
            }
        }
}
$NearExpirationSecrets | Sort-Object  category,expirationdate  | ft -autosize

$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
$filename = $Outputdirectory+"secretexport_"+$tdy+".csv"
$NearExpirationSecrets | Sort-Object category, expirationdate| export-csv -Path $filename -NoTypeInformation -Encoding utf8