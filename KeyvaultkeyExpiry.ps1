<#
written by Derrick Baxter
10/16/24
setup categories by dates to get more than just a certain date, but by ranges and expired secrets

Name      Category               ExpirationDate        KeyVaultName
----      --------               --------------        ------------
ted2      SecretExpired          12/2/2022 11:59:59 PM keyvault01
wildcard  SecretExpired          12/2/2022 11:59:59 PM KeyVault1
spncert   60-180DaySecretExpiry  1/14/2025 4:45:57 PM  KeyVault1
start     180-360DaySecretExpiry 9/12/2025 2:13:48 PM  KeyVault1
newsecret GT1YearDaySecretExpiry 1/3/2026 8:03:11 PM   KeyVault1
new21424  GT1YearDaySecretExpiry 2/15/2026 9:24:49 PM  KeyVault1

#>#>

connect-azaccount 
$kvnames = get-azkeyvault
$NearExpirationkey = @()
foreach($rgitem in $kvnames)
{
$KeyVault = Get-AzKeyVault -ResourceGroupName $rgitem.resourcegroupname -VaultName $rgitem.vaultname
    foreach ($kvitem in $keyvault)
        {
            $key = Get-AzKeyVaultKey -VaultName $kvitem.VaultName
            #$key
            $1Days = Get-Date (Get-Date).AddDays(1) -Format yyyyMMdd
            $7Days = Get-Date (Get-Date).AddDays(7) -Format yyyyMMdd
            $15Days = Get-Date (Get-Date).AddDays(15) -Format yyyyMMdd
            $30Days = Get-Date (Get-Date).AddDays(30) -Format yyyyMMdd
            $60Days = Get-Date (Get-Date).AddDays(60) -Format yyyyMMdd
            $180Days = Get-Date (Get-Date).AddDays(180) -Format yyyyMMdd
            $360days = Get-Date (Get-Date).AddDays(360) -Format yyyyMMdd
            $3600day = Get-Date (Get-Date).AddDays(3600) -Format yyyyMMdd
            $CurrentDate = Get-Date -Format yyyyMMdd


                foreach($cert in $key){
                    if($cert.Expires) {
                    $certExpiration = Get-Date $cert.Expires -Format yyyyMMdd
                    if($certexpiration -gt $360Days)
                        {
                            $NearExpirationkey += New-Object PSObject -Property @{
                                        Name           = $cert.Name;
                                        Category       = 'GT1YearDaycertExpiry';
                                        KeyVaultName   = $KeyVault.VaultName;
                                        ExpirationDate = $cert.Expires;
                                        Created         = $cert.created;
                                        Updated        = $cert.Updated;
                                        Notbefore      = $cert.NotBefore;
                                        id             =$cert.Id
                                    }
    
                        }  
                    
                    elseif($certExpiration -le $360Days -and $certexpiration -gt $180Days)
                    {
                        $NearExpirationkey += New-Object PSObject -Property @{
                                    Name           = $cert.Name;
                                    Category       = '180-360DaycertExpiry';
                                    KeyVaultName   = $KeyVault.VaultName;
                                    ExpirationDate = $cert.Expires;
                                    Created         = $cert.created;
                                    Updated        = $cert.Updated;
                                    Notbefore      = $cert.NotBefore;
                                    id             =$cert.Id
                                }

                    }  
                    elseif($certExpiration -le $180Days -and $certexpiration -gt $60Days)
                    {
                        $NearExpirationkey += New-Object PSObject -Property @{
                                    Name           = $cert.Name;
                                    Category       = '60-180DaycertExpiry';
                                    KeyVaultName   = $KeyVault.VaultName;
                                    ExpirationDate = $cert.Expires;
                                    Created         = $cert.created;
                                    Updated        = $cert.Updated;
                                    Notbefore      = $cert.NotBefore;
                                    id             =$cert.Id
                                }

                    }  
                    elseif($certExpiration -le $60Days -and $certexpiration -gt $30Days)
                        {
                            $NearExpirationkey += New-Object PSObject -Property @{
                                        Name           = $cert.Name;
                                        Category       = '30-60DaycertExpiry';
                                        KeyVaultName   = $KeyVault.VaultName;
                                        ExpirationDate = $cert.Expires;
                                        Created         = $cert.created;
                                        Updated        = $cert.Updated;
                                        Notbefore      = $cert.NotBefore;
                                        id             =$cert.Id
                                    }
    
                        }  
                    elseif($certExpiration -le $30Days -and $certexpiration -gt $15Days)
                        {
                            $NearExpirationkey += New-Object PSObject -Property @{
                                        Name           = $cert.Name;
                                        Category       = '15-30DaycertExpiry';
                                        KeyVaultName   = $KeyVault.VaultName;
                                        ExpirationDate = $cert.Expires;
                                        Created         = $cert.created;
                                        Updated        = $cert.Updated;
                                        Notbefore      = $cert.NotBefore;
                                        id             =$cert.Id
                                    }
    
                        }
                        elseif($certExpiration -le $15Days -and $certexpiration -gt $7Days)
                        {
                            $NearExpirationkey += New-Object PSObject -Property @{
                                        Name           = $cert.Name;
                                        Category       = '7-15DaycertExpiry';
                                        KeyVaultName   = $KeyVault.VaultName;
                                        ExpirationDate = $cert.Expires;
                                        Created         = $cert.created;
                                        Updated        = $cert.Updated;
                                        Notbefore      = $cert.NotBefore;
                                        id             =$cert.Id
                                    }
    
                        }
                        elseif($certExpiration -le $7Days -and $certexpiration -gt $1Days)
                        {
                            $NearExpirationkey += New-Object PSObject -Property @{
                                        Name           = $cert.Name;
                                        Category       = '1-7DaycertExpiry';
                                        KeyVaultName   = $KeyVault.VaultName;
                                        ExpirationDate = $cert.Expires;
                                        Created         = $cert.created;
                                        Updated        = $cert.Updated;
                                        Notbefore      = $cert.NotBefore;
                                        id             =$cert.Id
                                    }
    
                        }                      
                    elseif($certExpiration -lt $currentDate)
                    {
                        $NearExpirationkey += New-Object PSObject -Property @{
                                    Name           = $cert.Name;
                                    Category       = 'certExpired';
                                    KeyVaultName   = $KeyVault.VaultName;
                                    ExpirationDate = $cert.Expires;
                                    Created         = $cert.created;
                                    Updated        = $cert.Updated;
                                    Notbefore      = $cert.NotBefore;
                                    id             =$cert.Id
                                }

                    }
                }
        }
    }
}

$NearExpirationkey | Sort-Object  expirationdate, category  | ft -autosize

