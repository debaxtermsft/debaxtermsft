param([parameter(Position=0,mandatory)][string]$tenantId,
[parameter(Position=1,mandatory)] [string]$Outputdirectory)


connect-azaccount -tenantid $tenantId

$subscriptions = Get-AzSubscription -TenantId $tenantId

$NearExpirationkeys = @()

foreach ($subitem in $subscriptions){
        Set-AzContext -Subscription $subitem.id -Tenant $tenantId
    $kvnames = get-azkeyvault 

    if ($kvnames.count -eq 0){
        write-host "no kv" 
    }
    else {

    foreach ($kvitem in $kvnames)
            {
                $keys = Get-AzKeyVaultkey -VaultName $kvitem.VaultName
                $keys.count 
                if($keys.count -eq 0) {write-host "no keys in this kv"}
                else
                {
                    foreach ($keyitem in $keys)
                    {
                        $NearExpirationkeys += New-Object PSObject -Property @{
                            Name           = $keyitem.Name;
                            KeyVaultName   = $keyitem.VaultName;
                            ExpirationDate = $keyitem.Expires;
                            Created         = $keyitem.created;
                            Updated        = $keyitem.Updated;
                            Notbefore      = $keyitem.NotBefore;
                            id             =$keyitem.Id
                        }
                    }
                }
        }
    }
}
$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
$filename = $Outputdirectory+"keyexport_"+$tdy+".csv"
$NearExpirationkeys | export-csv -Path $filename -NoTypeInformation -Encoding utf8