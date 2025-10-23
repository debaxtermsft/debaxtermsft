<#
Written by Derrick Baxter 10/23/25
retrieves lastSigninActivity reports for Service Principals
add trailing \ for directory or it will put it into the root of last \
.\SPNLastSigninActivity.ps1 -tenantid "tenantguid" -outputdirectory "c:\temp\" -appowner "all"
if you want only 1st party applications
.\SPNLastSigninActivity.ps1 -tenantid "tenantguid" -outputdirectory "c:\temp\" -appowner "Microsoft 1st Party"
#>
param([parameter(mandatory=$false)][string] $tenantID,
    [parameter(mandatory)][validateset("All", "Microsoft 1st Party")] [string]$AppOwner,
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



if($AppOwner -eq "All")
{
    $apps = Get-MgServicePrincipal -all | Select-Object displayname, appid,AppOwnerOrganizationId | Sort-Object displayname
}
else 
{
    $apps = Get-MgServicePrincipal -top 25 | Select-Object displayname, appid,AppOwnerOrganizationId | Sort-Object displayname | Where-Object{$_.AppOwnerOrganizationId -eq "72f988bf-86f1-41af-91ab-2d7cd011db47" -or $_.AppOwnerOrganizationId -eq "f8cdef31-a31e-4b4a-93e4-5f571e91255a" }
}

$SPNObject =@()
foreach ($item in $apps) {
$filterapps = $item.appid
$getAppSAreport = get-mgbetaReportServicePrincipalSignInActivity -Filter "appId eq '$filterapps'" -Property *

if ($getAppSAreport -ne $null){
[string]$cdt = $item.additionalproperties.values
[string]$Lsia = $getAppSAreport.lastsigninactivity.lastsignindatetime
[string]$DCSIA  = $getAppSAreport.DelegatedClientSignInActivity.lastsigninDatetime
[string]$aacsia = $getAppSAreport.ApplicationAuthenticationClientSignInActivity.lastsigninDatetime
[string]$aarsia = $getAppSAreport.ApplicationAuthenticationResourceSignInActivity.lastsigninDatetime
[string]$drsia = $getAppSAreport.DelegatedResourceSignInActivity.LastSignInDateTime

[string]$LNIsia = $getAppSAreport.lastsigninactivity.LastNonInteractiveSignInDateTime

if($item.AppOwnerOrganizationId -eq "72f988bf-86f1-41af-91ab-2d7cd011db47" -or $item.AppOwnerOrganizationId -eq "f8cdef31-a31e-4b4a-93e4-5f571e91255a") 
{
    $Msft1stPartyApp = "Microsoft 1st Party App"
}
else {
    $Msft1stPartyApp = "Not MSFT"
}

 $SPNObject += New-Object Object |
                    Add-Member -NotePropertyName "SPNDisplayName" -NotePropertyValue $item.displayname -PassThru |
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
$file = $Outputdirectory+"SPNSigninActivity_"+$tdy+".csv"
$SPNObject | export-csv -path $file -NoTypeInformation -Encoding utf8

