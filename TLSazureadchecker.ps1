$tId = "7b69d5f1-a08a-4802-9c12-794ca524d88d"  # Add tenant ID from Azure Active Directory page on portal.
$tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
$agoDays = 30  # Will filter the log for $agoDays from the current date and time.
$startDate = (Get-Date).AddDays(-($agoDays)).ToString('yyyy-MM-dd')  # Get filter start date.
$pathForExport = "c:\temp\"  # The path to the local filesystem for export of the CSV file.

Connect-azuread
#Select-MgProfile "beta"  # Low TLS is available in Microsoft Graph preview endpoint.

# Define the filtering strings for interactive and non-interactive sign-ins.
$procDetailFunction = "x: x/key eq 'legacy tls (tls 1.0, 1.1, 3des)' and x/value eq '1'"

$SIIProperties =@()
$SINIProperties =@()
$SIWIProperties =@()

# Get the interactive and non-interactive sign-ins based on filtering clauses.
$legacy =  Get-AzureADAuditSignInLogs -All $true  -Filter "createdDateTime ge $startDate"  | 
Where-Object{$_.AuthenticationProcessingDetails.key -match "Legacy"}  | sort-object CreatedDateTime

write-host "SII"
if ($legacy.count -ge 1)
{
    $filterUsernames = $legacy | Select-Object userprincipalname | sort-object -Unique  userprincipalname
    foreach ($useritem in $filterUsernames)
    {
        $username = $useritem.userprincipalname 
        $clauses = (
            "createdDateTime ge $startDate",
            "signInEventTypes/any(t: t eq 'nonInteractiveUser')",
            "signInEventTypes/any(t: t eq 'servicePrincipal')",
            "userPrincipalName eq '$username'"
        )
        $SIIfilter = $clauses[0,3] -join " and "
        
        $signInsInteractive =  Get-AzureADAuditSignInLogs -all $true -filter $SIIfilter  | 
        Where-Object{$_.AuthenticationProcessingDetails.key -match "Legacy" -and $_.AuthenticationProcessingDetails.Value -eq "True"} | sort-object UserDisplayName -Unique
        
            foreach ($SIILog in $signInsInteractive)
            {
                write-host "Found Interactive Legacy TLS login for user " $siilog.UserDisplayName
                $userauthprocdetails0 = $SIILog.AuthenticationProcessingDetails.key[0]
                $userauthprocdetails1 = $SIILog.AuthenticationProcessingDetails.key[1]
            $SIIProperties += New-Object Object |
                Add-Member -NotePropertyName CorrelationId -NotePropertyValue $SIILog.CorrelationId -PassThru |
                Add-Member -NotePropertyName createdDateTime -NotePropertyValue $SIILog.createdDateTime -PassThru |
                Add-Member -NotePropertyName userPrincipalName -NotePropertyValue $SIILog.userprincipalname -PassThru |
                Add-Member -NotePropertyName userId -NotePropertyValue $SIILog.userId -PassThru |
                Add-Member -NotePropertyName UserDisplayName -NotePropertyValue $SIILog.UserDisplayName -PassThru |
                Add-Member -NotePropertyName AppDisplayName -NotePropertyValue $SIILog.appdisplayname -PassThru |
                Add-Member -NotePropertyName AppId -NotePropertyValue $SIILog.Appid -PassThru |
                Add-Member -NotePropertyName IPAddress -NotePropertyValue $SIILog.IPAddress -PassThru |
                Add-Member -NotePropertyName isInteractive -NotePropertyValue $SIILog.isInteractive -PassThru |
                Add-Member -NotePropertyName ResourceDisplayName -NotePropertyValue $SIILog.ResourceDisplayName -PassThru |
                Add-Member -NotePropertyName ResourceServicePrincipal -NotePropertyValue $SIILog.ResourceServicePrincipalId -PassThru |
                Add-Member -NotePropertyName ResourceId -NotePropertyValue $SIILog.ResourceId -PassThru |
                Add-Member -NotePropertyName UserAgent -NotePropertyValue $SIILog.UserAgent -PassThru |
                Add-Member -NotePropertyName AuthenticationProcessingDetails0 -NotePropertyValue $userauthprocdetails0 -PassThru |
                Add-Member -NotePropertyName AuthenticationProcessingDetails1 -NotePropertyValue $userauthprocdetails1 -PassThru |
                Add-Member -NotePropertyName authenticationRequirement -NotePropertyValue $SIILog.authenticationRequirement -PassThru
                
            }
             
            #Start-Sleep 1
   }

    
}
write-host "SINI"
if ($legacy.count -ge 1)
{
    $filterUsernames = $legacy | Select-Object userprincipalname | sort-object -Unique  userprincipalname
    foreach ($useritem in $filterUsernames)
    {
        $username = $useritem.userprincipalname 
        $clauses = (
            "createdDateTime ge $startDate",
            "signInEventTypes/any(t: t eq 'nonInteractiveUser')",
            "signInEventTypes/any(t: t eq 'servicePrincipal')",
            "userPrincipalName eq '$username'"
        )
        $SINIfilter = $clauses[0,1,3] -join " and "
        
        $signInsNInteractive =  Get-AzureADAuditSignInLogs -all $true -Filter $SINIfilter | 
        Where-Object{$_.AuthenticationProcessingDetails.key -match "Legacy" -and $_.AuthenticationProcessingDetails.Value -eq "True"} | sort-object UserDisplayName -Unique
        
            foreach ($SINILog in $signInsNInteractive)
            {
                write-host "Found NonInteractive Legacy TLS login for user " $sinilog.UserDisplayName
                $userauthprocdetails0 = $SINILog.AuthenticationProcessingDetails.key[0]
                $userauthprocdetails1 = $SINILog.AuthenticationProcessingDetails.key[1]
            $SINIProperties += New-Object Object |
                Add-Member -NotePropertyName CorrelationId -NotePropertyValue $SINILog.CorrelationId -PassThru |
                Add-Member -NotePropertyName createdDateTime -NotePropertyValue $SINILog.createdDateTime -PassThru |
                Add-Member -NotePropertyName userPrincipalName -NotePropertyValue $SINILog.userprincipalname -PassThru |
                Add-Member -NotePropertyName userId -NotePropertyValue $SINILog.userId -PassThru |
                Add-Member -NotePropertyName UserDisplayName -NotePropertyValue $SINILog.UserDisplayName -PassThru |
                Add-Member -NotePropertyName AppDisplayName -NotePropertyValue $SINILog.appdisplayname -PassThru |
                Add-Member -NotePropertyName AppId -NotePropertyValue $SINILog.Appid -PassThru |
                Add-Member -NotePropertyName IPAddress -NotePropertyValue $SINILog.IPAddress -PassThru |
                Add-Member -NotePropertyName isInteractive -NotePropertyValue $SINILog.isInteractive -PassThru |
                Add-Member -NotePropertyName ResourceDisplayName -NotePropertyValue $SINILog.ResourceDisplayName -PassThru |
                Add-Member -NotePropertyName ResourceServicePrincipal -NotePropertyValue $SINILog.ResourceServicePrincipalId -PassThru |
                Add-Member -NotePropertyName ResourceId -NotePropertyValue $SINILog.ResourceId -PassThru |
                Add-Member -NotePropertyName UserAgent -NotePropertyValue $SINILog.UserAgent -PassThru |
                Add-Member -NotePropertyName AuthenticationProcessingDetails0 -NotePropertyValue $userauthprocdetails0 -PassThru |
                Add-Member -NotePropertyName AuthenticationProcessingDetails1 -NotePropertyValue $userauthprocdetails1 -PassThru |
                Add-Member -NotePropertyName authenticationRequirement -NotePropertyValue $SINILog.authenticationRequirement -PassThru
                
            }
             
            # Start-Sleep 1
    }

    
}
$MGserviceprincipals = @()
$checkSPNlegacylogins =  Get-AzureADAuditSignInLogs -All $true -Filter "createdDateTime ge $startDate and signInEventTypes/any(t: t eq 'servicePrincipal')" | 
sort-object CreatedDateTime  | 
Where-Object{$_.AuthenticationProcessingDetails.key -match "Legacy"}
write-host "SIWI"

        $spnname = $spnitem.AppDisplayName
        $clauses = (
                "createdDateTime ge $startDate",
                "signInEventTypes/any(t: t eq 'servicePrincipal')",
                "appDisplayName eq '$spnname'"
            )
            $SIWIfilter = $clauses[0,1,2] -join " and "

            $signInsWorkloadIdentities =  Get-AzureADAuditSignInLogs -All $true -filter $SIWIfilter | ?{$_.AuthenticationProcessingDetails.key -match "Legacy"} 
            write-host "Found Legacy TLS login for SPN/app " $SPNItem.AppDisplayName
            foreach ($SIWILog in $signInsWorkloadIdentities)
                {
                    $authprocdetails0 = $SIWILog.AuthenticationProcessingDetails.key[0]
                    $authprocdetails1 = $SIWILog.AuthenticationProcessingDetails.key[1]
                $SIWIProperties += New-Object Object |
                    Add-Member -NotePropertyName CorrelationId -NotePropertyValue $SIWILog.CorrelationId -PassThru |
                    Add-Member -NotePropertyName createdDateTime -NotePropertyValue $SIWILog.createdDateTime -PassThru |
                    Add-Member -NotePropertyName AppDisplayName -NotePropertyValue $SIWILog.appdisplayname -PassThru |
                    Add-Member -NotePropertyName AppId -NotePropertyValue $SIWILog.Appid -PassThru |
                    Add-Member -NotePropertyName IPAddress -NotePropertyValue $SIWILog.IPAddress -PassThru |
                    Add-Member -NotePropertyName isInteractive -NotePropertyValue $SIWILog.isInteractive -PassThru |
                    Add-Member -NotePropertyName ResourceDisplayName -NotePropertyValue $SIWILog.ResourceDisplayName -PassThru |
                    Add-Member -NotePropertyName ResourceId -NotePropertyValue $SIWILog.ResourceId -PassThru |
                    Add-Member -NotePropertyName ResourceServicePrincipal -NotePropertyValue $SIWILog.ResourceServicePrincipalId -PassThru |
                    Add-Member -NotePropertyName ServicePrincipalDisplayName -NotePropertyValue $SIWILog.ServicePrincipalName -PassThru |
                    Add-Member -NotePropertyName ServicePrincipalId -NotePropertyValue $SIWILog.ServicePrincipalId -PassThru |
                    Add-Member -NotePropertyName AuthenticationProcessingDetails0 -NotePropertyValue $authprocdetails0 -PassThru |
                    Add-Member -NotePropertyName AuthenticationProcessingDetails1 -NotePropertyValue $authprocdetails1 -PassThru |
                    Add-Member -NotePropertyName authenticationRequirement -NotePropertyValue $SIWILog.authenticationRequirement -PassThru
                    
                    
                }

$SIIProperties | Export-Csv -Path ($pathForExport + "Interactive_lowTls_$tId_$tdy.csv") -NoTypeInformation
$SINIProperties | Export-Csv -Path ($pathForExport + "NONInteractive_lowTls_$tId_$tdy.csv") -NoTypeInformation
$SIWIProperties  | Export-Csv -Path ($pathForExport + "WorkloadIdentities_lowTls_$tId_$tdy.csv") -NoTypeInformation

