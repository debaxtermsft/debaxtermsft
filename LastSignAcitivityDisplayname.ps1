connect-mggraph -scopes "directory.read.all, auditlog.read.all, user.read.all" -TenantId <tenantid>

$users = get-mguser -all | select displayname, userprincipalname, mail, id | Sort-Object displayname -Unique
$SigninLogProperties =@()
foreach ($useritem in $users)
{
    write-host "looking up " $useritem.displayname
    $mail = $useritem.mail
    $displayname = $useritem.displayname
    $upn = $useritem.userprincipalname
    $auditlog =@()    

        $ApiUrl = "https://graph.microsoft.com/v1.0/users?`$filter=startswith(displayname,'$displayname')&`$select=displayName,userprincipalname,signInActivity"
        $auditlog = Invoke-MgGraphRequest -Uri $ApiUrl -method get


    foreach($thing in $auditlog.value)
        {

            if($thing.signinactivity -eq $null){write-host "No Signin Activity" $thing.userprincipalname}
            else
            {
                #write-host "Found Signin Activity... Logging"
                $dn = $thing.Displayname
                $upn = $thing.userprincipalname 
                $sirq = $thing.signinactivity.lastSignInRequestId
                $sidate = $thing.signinactivity.lastSignInDateTime
                $nirq = $thing.signinactivity.lastNonInteractiveSignInRequestId
                $nidate = $thing.signinactivity.lastNonInteractiveSignInDateTime

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
    start-sleep 1
}


$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
$outputfile = "c:\temp\signinactivity_"+$tdy+".csv"
$SigninLogProperties | export-csv -Path $outputfile -NoTypeInformation -Encoding UTF8