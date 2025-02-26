<# 
Written by Derrick Baxter
5/15/2023
Retrieves by graphapi the last signin audit logs for guest users - logs if they have or have not logged in.
signin activity does not report no signins

Update the $outputfile location from c:\temp\name as wanted - date and .csv are automatically added to avoid overwritting  

IMPORTANT!!!

To consent for users to run this script a global admin will need to run the following
-------------------------------------------------------------------------------------------

$sp = get-mgserviceprincipal -all| ?{$_.displayname -eq "Microsoft Graph"}
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
connect-mggraph -scopes "directory.read.all, auditlog.read.all, user.read.all" 

$mgusers =  (get-mguser -all | ?{$_.userprincipalname -like "*#EXT#*"}).userprincipalname
$SigninLogProperties =@()
foreach($guestuser in $mgusers)
{
$findname,$notneeded = $guestuser.Split('#EXT#')
$ApiUrl = "https://graph.microsoft.com/v1.0/users?`$filter=startswith(userprincipalname,'$findname')&`$select=displayName,userprincipalname,signInActivity"
write-host $apiurl


$auditlog = Invoke-MgGraphRequest -Uri $ApiUrl -method get


        foreach ($item in $auditlog.value){
            if($item.signinactivity.lastSignInRequestId -eq $null -or $item.signinactivity.lastNonInteractiveSignInRequestId -eq $null)
            {
                $dn = $item.Displayname
                $upn = $item.userprincipalname
                if($item.signinactivity.lastSignInRequestId -eq $null) 
                {
                $sirq = "No Interactive Signins"
                $sidate = "0000-00-00"
                }
                else 
                {
                    $sirq = $item.signinactivity.lastSignInRequestId
                    $sidate = $item.signinactivity.lastSignInDateTime
                }
                if($item.signinactivity.lastNonInteractiveSignInRequestId -eq $null)
                {
                    $nirq = "No NonInteractive Signins"
                    $nidate = "0000-00-00"
                }
                else 
                {
                    $nirq = $item.signinactivity.lastNonInteractiveSignInRequestId
                    $nidate = $item.signinactivity.lastNonInteractiveSignInDateTime
                }

                $SigninLogProperties += New-Object Object |
                                        Add-Member -NotePropertyName DisplayName -NotePropertyValue $dn -PassThru |
                                        Add-Member -NotePropertyName UserprincipalName -NotePropertyValue $upn -PassThru |
                                        Add-Member -NotePropertyName ObjectID -NotePropertyValue $item.id -PassThru |
                                        Add-Member -NotePropertyName LastSignin_Rq_ID -NotePropertyValue $sirq -PassThru |
                                        Add-Member -NotePropertyName LastSignin_Date -NotePropertyValue $sidate -PassThru |
                                        Add-Member -NotePropertyName LastNonInteractiveSignin_Rq_ID -NotePropertyValue $nirq -PassThru |
                                        Add-Member -NotePropertyName LastNonInteractiveSignin_Date -NotePropertyValue $nidate -PassThru 
            }
            else 
            {
                $dn = $item.Displayname
                $upn = $item.userprincipalname 
                $sirq = $item.signinactivity.lastSignInRequestId
                $sidate = $item.signinactivity.lastSignInDateTime
                $nirq = $item.signinactivity.lastNonInteractiveSignInRequestId
                $nidate = $item.signinactivity.lastNonInteractiveSignInDateTime
                $SigninLogProperties += New-Object Object |
                                        Add-Member -NotePropertyName DisplayName -NotePropertyValue $dn -PassThru |
                                        Add-Member -NotePropertyName UserprincipalName -NotePropertyValue $upn -PassThru |
                                        Add-Member -NotePropertyName ObjectID -NotePropertyValue $item.id -PassThru |
                                        Add-Member -NotePropertyName LastSignin_Rq_ID -NotePropertyValue $sirq -PassThru |
                                        Add-Member -NotePropertyName LastSignin_Date -NotePropertyValue $sidate -PassThru |
                                        Add-Member -NotePropertyName LastNonInteractiveSignin_Rq_ID -NotePropertyValue $nirq -PassThru |
                                        Add-Member -NotePropertyName LastNonInteractiveSignin_Date -NotePropertyValue $nidate -PassThru 
            }
        }
}
$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
$outputfile = "c:\temp\signinactivity_"+$tdy+".csv"
$SigninLogProperties | export-csv -Path $outputfile -NoTypeInformation -Encoding UTF8