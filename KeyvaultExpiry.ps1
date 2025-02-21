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
$NearExpirationSecrets = @()
foreach($rgitem in $kvnames)
{
$KeyVault = Get-AzKeyVault -ResourceGroupName $rgitem.resourcegroupname -VaultName $rgitem.vaultname
    foreach ($kvitem in $keyvault)
        {
            $secrets = Get-AzKeyVaultSecret -VaultName $kvitem.VaultName
            #$secrets
            $1Days = Get-Date (Get-Date).AddDays(1) -Format yyyyMMdd
            $7Days = Get-Date (Get-Date).AddDays(7) -Format yyyyMMdd
            $15Days = Get-Date (Get-Date).AddDays(15) -Format yyyyMMdd
            $30Days = Get-Date (Get-Date).AddDays(30) -Format yyyyMMdd
            $60Days = Get-Date (Get-Date).AddDays(60) -Format yyyyMMdd
            $180Days = Get-Date (Get-Date).AddDays(180) -Format yyyyMMdd
            $360days = Get-Date (Get-Date).AddDays(360) -Format yyyyMMdd
            $3600day = Get-Date (Get-Date).AddDays(3600) -Format yyyyMMdd
            $CurrentDate = Get-Date -Format yyyyMMdd


                foreach($secret in $secrets){
                    if($secret.Expires) {
                    $secretExpiration = Get-Date $secret.Expires -Format yyyyMMdd
                    if($secretexpiration -gt $360Days)
                        {
                            $NearExpirationSecrets += New-Object PSObject -Property @{
                                        Name           = $secret.Name;
                                        Category       = 'GT1YearDaySecretExpiry';
                                        KeyVaultName   = $KeyVault.VaultName;
                                        ExpirationDate = $secret.Expires;
                                    }
    
                        }  
                    
                    elseif($secretExpiration -le $360Days -and $secretexpiration -gt $180Days)
                    {
                        $NearExpirationSecrets += New-Object PSObject -Property @{
                                    Name           = $secret.Name;
                                    Category       = '180-360DaySecretExpiry';
                                    KeyVaultName   = $KeyVault.VaultName;
                                    ExpirationDate = $secret.Expires;
                                }

                    }  
                    elseif($secretExpiration -le $180Days -and $secretexpiration -gt $60Days)
                    {
                        $NearExpirationSecrets += New-Object PSObject -Property @{
                                    Name           = $secret.Name;
                                    Category       = '60-180DaySecretExpiry';
                                    KeyVaultName   = $KeyVault.VaultName;
                                    ExpirationDate = $secret.Expires;
                                }

                    }  
                    elseif($secretExpiration -le $60Days -and $secretexpiration -gt $30Days)
                        {
                            $NearExpirationSecrets += New-Object PSObject -Property @{
                                        Name           = $secret.Name;
                                        Category       = '30-60DaySecretExpiry';
                                        KeyVaultName   = $KeyVault.VaultName;
                                        ExpirationDate = $secret.Expires;
                                    }
    
                        }  
                    elseif($secretExpiration -le $30Days -and $secretexpiration -gt $15Days)
                        {
                            $NearExpirationSecrets += New-Object PSObject -Property @{
                                        Name           = $secret.Name;
                                        Category       = '15-30DaySecretExpiry';
                                        KeyVaultName   = $KeyVault.VaultName;
                                        ExpirationDate = $secret.Expires;
                                    }
    
                        }
                        elseif($secretExpiration -le $15Days -and $secretexpiration -gt $7Days)
                        {
                            $NearExpirationSecrets += New-Object PSObject -Property @{
                                        Name           = $secret.Name;
                                        Category       = '7-15DaySecretExpiry';
                                        KeyVaultName   = $KeyVault.VaultName;
                                        ExpirationDate = $secret.Expires;
                                    }
    
                        }
                        elseif($secretExpiration -le $7Days -and $secretexpiration -gt $1Days)
                        {
                            $NearExpirationSecrets += New-Object PSObject -Property @{
                                        Name           = $secret.Name;
                                        Category       = '1-7DaySecretExpiry';
                                        KeyVaultName   = $KeyVault.VaultName;
                                        ExpirationDate = $secret.Expires;
                                    }
    
                        }                      
                    elseif($secretExpiration -lt $currentDate)
                    {
                        $NearExpirationSecrets += New-Object PSObject -Property @{
                                    Name           = $secret.Name;
                                    Category       = 'SecretExpired';
                                    KeyVaultName   = $KeyVault.VaultName;
                                    ExpirationDate = $secret.Expires;
                                }

                    }
                }
        }
    }
}

$NearExpirationSecrets | Sort-Object  expirationdate, category
