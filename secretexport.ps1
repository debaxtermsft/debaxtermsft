param([parameter(Position=0,mandatory)][string]$tenantId,
[parameter(Position=1,mandatory)] [string]$Outputdirectory)


connect-azaccount -tenantid $tenantId

$subscriptions = Get-AzSubscription -TenantId $tenantId

$NearExpirationSecrets = @()

foreach ($subitem in $subscriptions){
        Set-AzContext -Subscription $subitem.id -Tenant $tenantId
    $kvnames = get-azkeyvault 

    if ($kvnames.count -eq 0){
        write-host "no kv" 
    }
    else {

    foreach ($kvitem in $kvnames)
            {
                $secrets = Get-AzKeyVaultSecret -VaultName $kvitem.VaultName
                $secrets.count 
                if($secrets.count -eq 0) {write-host "no secrets in this kv"}
                else
                {
                    foreach ($secitem in $secrets)
                    {
                        $NearExpirationSecrets += New-Object PSObject -Property @{
                            Name           = $secitem.Name;
                            KeyVaultName   = $secitem.VaultName;
                            ExpirationDate = $secitem.Expires;
                            Created         = $secitem.created;
                            Updated        = $secitem.Updated;
                            Notbefore      = $secitem.NotBefore;
                            id             =$secitem.Id
                        }
                    }
                }
        }
    }
}
$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
$filename = $Outputdirectory+"secretexport_"+$tdy+".csv"
$NearExpirationSecrets | export-csv -Path $filename -NoTypeInformation -Encoding utf8