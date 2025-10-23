<#
Written by Derrick Baxter 10/23/25
retrieves lastSigninActivity reports for Service Principals
add trailing \ for directory or it will put it into the root of last \
NOTE: MAY TAKE A VERY LONG TIME!!! BE PATIENT (throttling may be added if reports of this come in)
.\SPNLastSigninActivity.ps1 -tenantid "tenantguid" -outputdirectory "c:\temp\" -appowner "all"
if you want only 1st party applications
.\SPNLastSigninActivity.ps1 -tenantid "tenantguid" -outputdirectory "c:\temp\" -appowner "Microsoft 1st Party"
if you want no 1st party applications
.\SPNLastSigninActivity.ps1 -tenantid "tenantguid" -outputdirectory "c:\temp\" -appowner "NoMSFT"
if you want 1 applications report
.\SPNLastSigninActivity.ps1 -tenantid "tenantguid" -outputdirectory "c:\temp\" -appowner "Appid" -EnterAppId "AppId from SPN"
 

#>
param([parameter(mandatory=$false)][string] $tenantID,
    [parameter(mandatory)][validateset("All", "NoMSFT","Microsoft 1st Party", "AppId")] [string]$AppOwner,
    [parameter(mandatory=$false)] [string]$EnterAppId,
    [parameter(mandatory)] [string]$Outputdirectory)

# Connect to Microsoft Graph

try
    {
        Get-MGDomain -ErrorAction Stop > $null
    }
catch
    {
        connect-mggraph -scopes "directory.read.all, application.read.all, auditlog.read.all" -TenantId $tenantID
    }



if ($AppOwner -eq "All") {
    $apps = Get-MgServicePrincipal -all | Select-Object displayname, appid, AppOwnerOrganizationId | Sort-Object displayname
    write-host "There are " $apps.count " service principals to scan, please be patient"
}
elseif ($AppOwner -eq "NoMSFT") {
    $apps = Get-MgServicePrincipal -all | Select-Object displayname, appid, AppOwnerOrganizationId | Sort-Object displayname | Where-Object { $_.AppOwnerOrganizationId -ne "72f988bf-86f1-41af-91ab-2d7cd011db47" -and $_.AppOwnerOrganizationId -ne "f8cdef31-a31e-4b4a-93e4-5f571e91255a" }
    write-host "There are " $apps.count " service principals to scan, please be patient"
}
elseif ($AppOwner -eq "AppId") {
    $apps = Get-MgServicePrincipal -all | Select-Object displayname, appid, AppOwnerOrganizationId | Sort-Object displayname | Where-Object { $_.Appid -eq $EnterAppId }
    write-host "There are " $apps.count " service principals to scan, please be patient"
}
else {
    $apps = Get-MgServicePrincipal -all | Select-Object displayname, appid, AppOwnerOrganizationId | Sort-Object displayname | Where-Object { $_.AppOwnerOrganizationId -eq "72f988bf-86f1-41af-91ab-2d7cd011db47" -or $_.AppOwnerOrganizationId -eq "f8cdef31-a31e-4b4a-93e4-5f571e91255a" }
    write-host "There are " $apps.count " service principals to scan, please be patient"
}

$total = $apps.Count
$count = 0
Write-Host "Processing $total service principals..."
$SPNObject =@()

foreach ($item in $apps) {
#code for counter and percentage
    $count++
    $percent        = [math]::Round(($count / $total) * 100, 2)
    Clear-Host
    Write-Host "Processing: $count of $total ($percent % complete)"
    $filterapps     = $item.appid
    $getAppSAreport = get-mgbetaReportServicePrincipalSignInActivity -Filter "appId eq '$filterapps'" -Property *


if ($null -ne $getAppSAreport){
    [string]$cdt    = $item.additionalproperties.values
    [string]$Lsia   = $getAppSAreport.lastsigninactivity.lastsignindatetime
    [string]$DCSIA  = $getAppSAreport.DelegatedClientSignInActivity.lastsigninDatetime
    [string]$aacsia = $getAppSAreport.ApplicationAuthenticationClientSignInActivity.lastsigninDatetime
    [string]$aarsia = $getAppSAreport.ApplicationAuthenticationResourceSignInActivity.lastsigninDatetime
    [string]$drsia  = $getAppSAreport.DelegatedResourceSignInActivity.LastSignInDateTime
    [string]$LNIsia = $getAppSAreport.lastsigninactivity.LastNonInteractiveSignInDateTime
#write-host "LAS Report date" $LAS " for " $item.displayname

        if($item.AppOwnerOrganizationId -eq "72f988bf-86f1-41af-91ab-2d7cd011db47" -or $item.AppOwnerOrganizationId -eq "f8cdef31-a31e-4b4a-93e4-5f571e91255a") 
        {
            $Msft1stPartyApp = "Microsoft 1st Party App"
        }
        elseif($item.AppOwnerOrganizationId -eq $tenantID){
            $Msft1stPartyApp = "Home Tenant"
        }
        else {
            $Msft1stPartyApp = "Not MSFT"
        }

        $SPNObject += New-Object Object |
                            Add-Member -NotePropertyName "SPNDisplayName" -NotePropertyValue $item.displayname -PassThru |
                            Add-Member -NotePropertyName "SPNappId" -NotePropertyValue $item.AppId -PassThru |
                            Add-Member -NotePropertyName "SPNId" -NotePropertyValue $item.Id -PassThru |
                            Add-Member -NotePropertyName "AppOwnerOrganizationId" -NotePropertyValue $item.AppOwnerOrganizationId -PassThru |
                            Add-Member -NotePropertyName "Microsoft 1st PartyApp" -NotePropertyValue $Msft1stPartyApp -PassThru |
                            Add-Member -NotePropertyName "SPNCreatedDateTime" -NotePropertyValue $cdt -PassThru |
                            Add-Member -NotePropertyName "SPNLastSigninActivityDate" -NotePropertyValue $Lsia -PassThru |
                            Add-Member -NotePropertyName "SPNNonInteractiveLastSigninActivityDate" -NotePropertyValue $LNIsia -PassThru |
                            Add-Member -NotePropertyName "SPNApplicationAuthenticationClientSignInActivity" -NotePropertyValue $aacsia -PassThru | 
                            Add-Member -NotePropertyName "SPNApplicationAuthenticationResourceSignInActivity" -NotePropertyValue $aarsia -PassThru |
                            Add-Member -NotePropertyName "SPNDelegatedClientSignInActivity" -NotePropertyValue $DCSIA -PassThru |
                            Add-Member -NotePropertyName "SPNDelegatedResourceSignInActivity" -NotePropertyValue $drsia -PassThru 
        }
else{
    [string]$cdt    = $item.additionalproperties.values
    [string]$Lsia   = "Null"
    [string]$DCSIA  = "Null"
    [string]$aacsia = "Null"
    [string]$aarsia = "Null"
    [string]$drsia  = "Null"
    [string]$LNIsia = "Null"
        if ($item.AppOwnerOrganizationId -eq "72f988bf-86f1-41af-91ab-2d7cd011db47" -or $item.AppOwnerOrganizationId -eq "f8cdef31-a31e-4b4a-93e4-5f571e91255a") {
            $Msft1stPartyApp = "Microsoft 1st Party App"
        }
        elseif ($item.AppOwnerOrganizationId -eq $tenantID) {
            $Msft1stPartyApp = "Home Tenant"
        }
        else {
            $Msft1stPartyApp = "Not MSFT"
        }

        $SPNObject += New-Object Object |
                            Add-Member -NotePropertyName "SPNDisplayName" -NotePropertyValue $item.displayname -PassThru |
                            Add-Member -NotePropertyName "SPNappId" -NotePropertyValue $item.AppId -PassThru |
                            Add-Member -NotePropertyName "SPNId" -NotePropertyValue $item.Id -PassThru |
                            Add-Member -NotePropertyName "AppOwnerOrganizationId" -NotePropertyValue $item.AppOwnerOrganizationId -PassThru |
                            Add-Member -NotePropertyName "Microsoft 1st PartyApp" -NotePropertyValue $Msft1stPartyApp -PassThru |
                            Add-Member -NotePropertyName "SPNCreatedDateTime" -NotePropertyValue $cdt -PassThru |
                            Add-Member -NotePropertyName "SPNLastSigninActivityDate" -NotePropertyValue $Lsia -PassThru |
                            Add-Member -NotePropertyName "SPNNonInteractiveLastSigninActivityDate" -NotePropertyValue $LNIsia -PassThru |
                            Add-Member -NotePropertyName "SPNApplicationAuthenticationClientSignInActivity" -NotePropertyValue $aacsia -PassThru | 
                            Add-Member -NotePropertyName "SPNApplicationAuthenticationResourceSignInActivity" -NotePropertyValue $aarsia -PassThru |
                            Add-Member -NotePropertyName "SPNDelegatedClientSignInActivity" -NotePropertyValue $DCSIA -PassThru |
                            Add-Member -NotePropertyName "SPNDelegatedResourceSignInActivity" -NotePropertyValue $drsia -PassThru 
 }
}

$SPNObject | ft 

$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
$file = $Outputdirectory+"SPNSigninActivity_"+$AppOwner+"_"+$tdy+".csv"
$SPNObject | export-csv -path $file -NoTypeInformation -Encoding utf8