<#
Written By Derrick Baxter 
8/18/23
This script will export all API (Principals) that have been granted permissions to APPs

example: 
./AzureOAuthAppConsentedAPIPermissions.ps1 -outputdirectory "c:\temp" 

A global administrator will need to consent to permissions first if the person running the below script is not a GA.
#----------start consent script
$sp = get-mgserviceprincipal -all| ?{$_.displayname -eq "Microsoft Graph"}
$resource = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$principalid = "users object id"
$scope1 ="group.read.all"
$scope2 ="directory.read.all"
$scope3 ="user.read.all"
$scope4 ="Application.Read.All"
$today = Get-Date -Format "yyyy-MM-dd"
$expiredate1 = get-date
$expiredate2 = $expiredate1.AddDays(365).ToString("yyyy-MM-dd")
$params = @{
    ClientId = $SP.Id
    ConsentType = "Principal"
    ResourceId = $resource.id
    principalId = $principalid
    Scope = "$scope1" + " " + "$scope2"+ " " + "$scope3"
    startTime = "$today"
    expiryTime = "$expiredate2"
    
}
$InitialConsented = New-MgOauth2PermissionGrant -BodyParameter $params
#----------end consent script
#> 
#----------start app perms script
#open a new administrator powershell window
#install-module -name microsoft.graph -scope allusers

param([parameter(Position=1,mandatory)] [string]$Outputdirectory)

try
    {
        Get-MGDomain -ErrorAction Stop > $null
    }
catch
    {
        connect-mggraph -scopes "directory.read.all, application.read.all, user.read.all, group.read.all"
    }
import-module Microsoft.Graph.Identity.SignIns -force
$AppPermProperties =@()
$oauth = Get-MgOauth2PermissionGrant -All 

foreach($item in $oauth)
{
    $spnapp = Get-MgServicePrincipal -ServicePrincipalId $item.ClientId
    if ($item.ConsentType -eq "Principal")
    {
        $principalid = get-mguser -UserId $item.principalid | Select-Object DisplayName, id
        $AppPermProperties += New-Object Object |
                                Add-Member -NotePropertyName AppDisplayName         -NotePropertyValue $spnapp.displayname      -PassThru |
                                Add-Member -NotePropertyName AppClientID            -NotePropertyValue $item.clientid           -PassThru |
                                Add-Member -NotePropertyName AppPermissionsScope    -NotePropertyValue $item.scope              -PassThru |
                                Add-Member -NotePropertyName ObjectName             -NotePropertyValue $principalid.displayname -PassThru |
                                Add-Member -NotePropertyName ObjectID               -NotePropertyValue $principalid.id          -PassThru
    }
    else
    {
        $principalid = "AllPrincipals"
        $AppPermProperties += New-Object Object |
                                Add-Member -NotePropertyName AppDisplayName         -NotePropertyValue $spnapp.displayname  -PassThru |
                                Add-Member -NotePropertyName AppClientID            -NotePropertyValue $item.clientid       -PassThru |
                                Add-Member -NotePropertyName AppPermissionsScope    -NotePropertyValue $item.scope          -PassThru |
                                Add-Member -NotePropertyName ObjectName             -NotePropertyValue $principalid         -PassThru |
                                Add-Member -NotePropertyName ObjectID               -NotePropertyValue $principalid         -PassThru
    }
}

$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
$outputfile = $Outputdirectory+"OauthAPP_APIConsentedPerms_"+$tdy+".csv"
$apppermproperties |sort-object -Property AppDisplayName, objectname| export-csv -Path $outputfile -NoTypeInformation -Encoding UTF8
#----------end app perms script
 