<# 
Written by Derrick Baxter
4/11/2023
Retrieves by graphapi the last signin audit logs
pick the signin activity below (unrem) and run
Update the $outputfile location from c:\temp\name as wanted - date and .csv are automatically added to avoid overwritting 

IMPORTANT!!!

To consent for users to run this script a global admin will need to run the following
-------------------------------------------------------------------------------------------

$sp = get-mgserviceprincipal  -all| ?{$_.displayname -eq "Microsoft Graph"}
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

param([parameter(mandatory)][validateset("UserPrincipalName", "Date","All")][string]$SignInActivityBy,
            [parameter(mandatory=$false)][string]$EnterUPN,
            [parameter(mandatory=$false)][validateset("Date Less Than","Date Less Than or EQ", "Date Greater Than", "Date Greater Than or EQ")][string]$DateSelect,
            [parameter(mandatory=$false)][string]$Date,
            [parameter(mandatory)] [string]$Outputdirectory)


$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
$filename = $Outputdirectory+$resourcequestion+"_"+$NameorIDSelect+"_"+$NameorID+"_"+$skipAnswer+"_"+$tdy+".csv"


connect-mggraph -scopes "directory.read.all, auditlog.read.all, user.read.all" -TenantId <tenantid>

switch -exact ($SignInActivityBy) 
            {
                "Cancel" {exit}
                "UserprincipalName"
                {
                    $ApiHeader1 = "https://graph.microsoft.com/v1.0/users?`$filter=startswith(userprincipalname,'"
                    $ApiFooter1 = "')&`$select=displayName,userprincipalname,signInActivity,lastPasswordChangeDateTime"
                    $ApiUrl     = $ApiHeader1+$EnterUPN+$ApiFooter1
                    #$ApiUrl = "https://graph.microsoft.com/v1.0/users?`$filter=startswith(userprincipalname,'derrick.baxter@domain.onmicrosoft.com')&`$select=displayName,userprincipalname,signInActivity,lastPasswordChangeDateTime"
                }
                "Date"
                {
                    $ApiHeader1 = "https://graph.microsoft.com/v1.0/users?`$filter=signInActivity/lastSignInDateTime"
                    if($DateSelect -eq "Date Less Than")
                    {
                        $dateeq = " lt "
                    }
                    elseif($DateSelect -eq "Date Greater Than") {
                        $dateeq = " gt "
                    }
                    elseif($DateSelect -eq "Date Less Than or EQ") {
                        $dateeq = " le "
                    }
                    else
                    {
                        $dateeq = " ge "
                    }
                    $ApiFooter1 = "&`$select=displayName,userprincipalname,lastPasswordChangeDateTime,signInActivity"
                    $ApiUrl     = $ApiHeader1+$dateeq+$date+$ApiFooter1
                    #$ApiUrl = "https://graph.microsoft.com/v1.0/users?`$filter=signInActivity/lastSignInDateTime le 2023-04-11T00:00:00Z&`$select=displayName,userprincipalname,lastPasswordChangeDateTime,signInActivity"

                }
                default
                {
                    $ApiUrl = "https://graph.microsoft.com/v1.0/users?`$select=displayName,lastPasswordChangeDateTime,signInActivity"
                }
            }



$SigninLogProperties =@()
$auditlog = Invoke-MgGraphRequest -Uri $ApiUrl -method get
$checkformorelogs = $auditlogusers.'@odata.nextlink'
do
{
    foreach ($item in $auditlog.value){
     $dn = $item.Displayname
     $upn = $item.userprincipalname 
     $sirq = $item.signinactivity.lastSignInRequestId
     $sidate = $item.signinactivity.lastSignInDateTime
     $nirq = $item.signinactivity.lastNonInteractiveSignInRequestId
     $nidate = $item.signinactivity.lastNonInteractiveSignInDateTime
     $passchangeDateTime = $item.signinactivity.LastPasswordChangeDateTime
     $SigninLogProperties += New-Object Object |
                                Add-Member -NotePropertyName DisplayName -NotePropertyValue $dn -PassThru |
                                Add-Member -NotePropertyName UserprincipalName -NotePropertyValue $upn -PassThru |
                                Add-Member -NotePropertyName ObjectID -NotePropertyValue $item.id -PassThru |
                                Add-Member -NotePropertyName LastPasswordChangeDateTime -NotePropertyValue $passchangeDateTime -PassThru |
                                Add-Member -NotePropertyName LastSignin_Rq_ID -NotePropertyValue $sirq -PassThru |
                                Add-Member -NotePropertyName LastSignin_Date -NotePropertyValue $sidate -PassThru |
                                Add-Member -NotePropertyName LastNonInteractiveSignin_Rq_ID -NotePropertyValue $nirq -PassThru |
                                Add-Member -NotePropertyName LastNonInteractiveSignin_Date -NotePropertyValue $nidate -PassThru 
    }
    $checkformorelogs = $auditlog.'@odata.nextlink'
    
    if($checkformorelogs -ne $null)
    {write-host "getting more logs"
    $auditlog = Invoke-MgGraphRequest -Uri $checkformorelogs -method get
    }
}
while ($checkformorelogs -ne $null)
$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
$outputfile = "c:\temp\signinactivity_"+$tdy+".csv"
$SigninLogProperties | export-csv -Path $outputfile -NoTypeInformation -Encoding UTF8