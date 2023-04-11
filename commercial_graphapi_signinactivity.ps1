<# 
Written by Derrick Baxter
4/11/2023
Retieves by graphapi the last signin audit logs
pick the signin activity below (unrem) and run
Update the $outputfile location from c:\temp\name as wanted - date and .csv are automatically added to avoid overwritting 
#>
connect-mggraph -scopes "directory.read.all, auditlog.read.all, user.read.all" -TenantId <tenantid>


#by UPN
#$ApiUrl = "https://graph.microsoft.com/v1.0/users?`$filter=startswith(userprincipalname,'derrick.baxter@saviors18twd.onmicrosoft.com')&`$select=displayName,userprincipalname,signInActivity"
#by date
#$ApiUrl = "https://graph.microsoft.com/v1.0/users?`$filter=signInActivity/lastSignInDateTime le 2023-04-11T00:00:00Z&`$select=displayName,userprincipalname,signInActivity"

#users
$ApiUrl = "https://graph.microsoft.com/v1.0/users?`$select=displayName,signInActivity"

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
     $SigninLogProperties += New-Object Object |
                                Add-Member -NotePropertyName DisplayName -NotePropertyValue $dn -PassThru |
                                Add-Member -NotePropertyName UserprincipalName -NotePropertyValue $upn -PassThru |
                                Add-Member -NotePropertyName ObjectID -NotePropertyValue $item.id -PassThru |
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