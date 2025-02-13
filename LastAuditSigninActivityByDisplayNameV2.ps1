<# 
Written by Derrick Baxter
4/19/2023

2/13/25 updated w html formatting and single user selection

CSV output
.\LastSigninActivity.ps1 -tenandID <guid> -groupquestion All -Outputdirectory "c:\temp\" -ExportFileType CSV
.\LastSigninActivity.ps1 -tenandID <guid> -groupquestion objectid -objectid <users objectid> -Outputdirectory "c:\temp\" -ExportFileType CSV
HTML output
.\LastSigninActivity.ps1 -tenandID <guid> -groupquestion All -Outputdirectory "c:\temp\" -ExportFileType HTML
.\LastSigninActivity.ps1 -tenandID <guid> -groupquestion objectid -objectid <users objectid> -Outputdirectory "c:\temp\" -ExportFileType HTML


Retrieves by graphapi the last signin audit logs by Display Name for ALL USERS and will take a long time.
pick the signin activity below (unrem) and run
Update the $outputfile location from c:\temp\name as wanted - date and .csv are automatically added to avoid overwritting 

IMPORTANT!!!

To consent for users to run this script a global admin will need to run the following
-------------------------------------------------------------------------------------------

$sp = get-mgserviceprincipal | ?{$_.displayname -eq "Microsoft Graph"}
$resource = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$principalid = "users object id"
$scope1 ="auditlog.read.all"
$scope2 ="directory.read.all"
$scope3 ="user.read.all"
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
-------------------------------------------------------------------------------------------
You may need to update the connect-mggraph to have the -environment USGov or as needed -tenantid <tenantid> can be added as needed.


#>

param([parameter(mandatory)][string] $tenandID,
            [parameter (mandatory)][validateset("All", "ObjectID")] [string]$groupquestion,
            [parameter (mandatory)][validateset("HTML", "CSV")] [string]$ExportFileType,
            [parameter(mandatory=$false)][string]$ObjectID,
            [parameter(mandatory)] [string]$Outputdirectory)

$WarningPreference = "SilentlyContinue"    

Try{
connect-mggraph -scopes "directory.read.all, auditlog.read.all, user.read.all" -TenantId $tenantid
}
catch{break}


if($groupquestion -eq "All")
{
   $users = get-mguser -all | Select-Object displayname, id | Sort-Object displayname
}
else
{
  $users = get-mguser -UserId $objectid | Select-Object id, displayname}

$SigninLogProperties =@()
$counter = 0
foreach ($useritem in $users)
{
    write-host "looking up " $useritem.displayname
    $displayname = $useritem.displayname
    $displayname
    $id = $useritem.id
    $auditlog =@()    
    $ap1 = "https://graph.microsoft.com/v1.0/users/"
    $ap2 = "?&`$select=displayName,userprincipalname,signInActivity"
    $ApiUrl = $ap1 + $id + $ap2
    $apiurl

    $auditlog = Invoke-MgGraphRequest -Uri  $apiurl -method get
    $dn = $auditlog.Displayname
    $upn = $auditlog.userprincipalname 
    $id = $auditlog.id
    $sirq = $auditlog.signinactivity.lastSignInRequestId
    $sidate = $auditlog.signinactivity.lastSignInDateTime
    $nirq = $auditlog.signinactivity.lastNonInteractiveSignInRequestId
    $nidate = $auditlog.signinactivity.lastNonInteractiveSignInDateTime
    if($sirq -eq $null -and $nirq -eq $null)    { write-host "no nonint or int logs"}
    else{
        write-host "Found Signin Activity... Logging"
        $SigninLogProperties += New-Object Object |
                                Add-Member -NotePropertyName DisplayName -NotePropertyValue $dn -PassThru |
                                Add-Member -NotePropertyName UserprincipalName -NotePropertyValue $upn -PassThru |
                                Add-Member -NotePropertyName ObjectID -NotePropertyValue $id -PassThru |
                                Add-Member -NotePropertyName LastSignin_Rq_ID -NotePropertyValue $sirq -PassThru |
                                Add-Member -NotePropertyName LastSignin_Date -NotePropertyValue $sidate -PassThru |
                                Add-Member -NotePropertyName LastNonInteractiveSignin_Rq_ID -NotePropertyValue $nirq -PassThru |
                                Add-Member -NotePropertyName LastNonInteractiveSignin_Date -NotePropertyValue $nidate -PassThru 
    }
    $counter++
    if($counter = 2000)
    {
    start-sleep 5
    $counter = 0
    }
}

$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
if($ExportFileType -eq "CSV")
{
    $outputfile = $Outputdirectory + "signinactivity_"+$tdy+".csv"
    $SigninLogProperties | export-csv -Path $outputfile -NoTypeInformation -Encoding UTF8
}
else
{
$htmlfile = $Outputdirectory + "signinactivity_"+$tdy+".html"

$cssStyle = @"
<style>
    table {
        width: 100%;
        border-collapse: collapse;
    }
    th, td {
        border: 1px solid #dddddd;
        text-align: left;
        padding: 8px;
    }
    tr:nth-child(even) {
        background-color: #f2f2f2;
    }
    th {
        background-color: #4CAF50;
        color: white;
    }
</style>
"@

$htmlContent = $SigninLogProperties | Sort-object DisplayName | ConvertTo-Html -Title "Last Signin Activity by DisplayName" -As "Table"
$htmlContent = $htmlContent -replace "</head>", "$cssStyle`n</head>"
$htmlContent | Out-File $htmlfile
}