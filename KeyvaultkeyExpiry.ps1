<#
written by Derrick Baxter
10/16/24
updated 
8/7/25 params and fixed some issues, added output file

setup categories by dates to get more than just a certain date, but by ranges and expired keys

Name      Category               ExpirationDate        KeyVaultName
----      --------               --------------        ------------
ted2      keyExpired          12/2/2022 11:59:59 PM keyvault01
wildcard  keyExpired          12/2/2022 11:59:59 PM KeyVault1
spncert   60-180DaykeyExpiry  1/14/2025 4:45:57 PM  KeyVault1
start     180-360DaykeyExpiry 9/12/2025 2:13:48 PM  KeyVault1
newkey GT1YearDaykeyExpiry 1/3/2026 8:03:11 PM   KeyVault1
new21424  GT1YearDaykeyExpiry 2/15/2026 9:24:49 PM  KeyVault1

.\keyvaultkeyexpiration.ps1 -tenantid "tenantid" -outputdirectory "c:\temp\"
make sure to add the trailing \ on the path 
#>#>

param([parameter(Position=0,mandatory)][string]$tenantId,
[parameter(Position=1,mandatory)] [string]$Outputdirectory)


connect-azaccount -tenantid $tenantId
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
        write-host "no kv" 
    }
    else {


            $kvnames = get-azkeyvault

            foreach($rgitem in $kvnames)
            {
            #$KeyVault = Get-AzKeyVault -ResourceGroupName $rgitem.resourcegroupname -VaultName $rgitem.vaultname
                #foreach ($kvitem in $keyvault)
                    #{
                        $keys = Get-AzKeyVaultkey -VaultName $rgitem.VaultName
                        #$keys



                            foreach($key in $keys){
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
                                                    id             =$key.Id
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
                                                id             =$key.Id
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
                                                id             =$key.Id
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
                                                    id             =$key.Id
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
                                                    id             =$key.Id
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
                                                    id             =$key.Id
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
                                                    id             =$key.Id
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
                                                id             =$key.Id

                                            }

                                }

                            }
                            elseif($key.expires -eq $null) {
                                $NearExpirationkeys += New-Object PSObject -Property @{
                                    Name           = $key.Name;
                                    Category       = 'keyNotSetOrNull';
                                    KeyVaultName   = $key.vaultname;
                                    ExpirationDate = $key.Expires;
                                    Created         = $key.created;
                                    Updated        = $key.Updated;
                                    Notbefore      = $key.NotBefore;
                                    id             =$key.Id

                                }
                            }
                    }
                #}
            }
        }
}
$NearExpirationkeys | Sort-Object  category,expirationdate  | ft -autosize

$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
$filename = $Outputdirectory+"keyexport_"+$tdy+".csv"
$NearExpirationkeys | Sort-Object category, expirationdate| export-csv -Path $filename -NoTypeInformation -Encoding utf8