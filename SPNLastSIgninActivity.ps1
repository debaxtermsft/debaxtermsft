connect-mggraph -scopes "directory.read.all, application.read.all, auditlog.read.all"

$apps = Get-MgServicePrincipal -all | Select-Object displayname, appid | Sort-Object displayname

$SPNObject =@()
$reports =@()
foreach ($item in $apps) {
write-host "item appid" $item.appid
$filterapps = $item.appid
$getAppSAreport = get-mgbetaReportServicePrincipalSignInActivity -Filter "appId eq '$filterapps'" -Property *
$getAppSAreport.lastsigninactivity.lastsignindatetime

$reports += $getAppSAreport

if ($getAppSAreport -ne $null){
write-host "displayname of spn " $item.displayname
write-host "reports count of activity" $reports.count
[string]$Lsia = $getAppSAreport.lastsigninactivity.lastsignindatetime
$DCSIA  = $getAppSAreport.DelegatedClientSignInActivity.lastsigninDatetime
$aacsia = $getAppSAreport.ApplicationAuthenticationClientSignInActivity.lastsigninDatetime
$aarsia = $getAppSAreport.ApplicationAuthenticationResourceSignInActivity.lastsigninDatetime
$drsia = $getAppSAreport.DelegatedResourceSignInActivity.LastSignInDateTime
write-host "LAS Report date" $LAS " for " $item.displayname

 $SPNObject += New-Object Object |
                    Add-Member -NotePropertyName "SPNDisplayName" -NotePropertyValue $item.displayname -PassThru |
                    Add-Member -NotePropertyName "SPNLastSigninActivityDate" -NotePropertyValue $Lsia -PassThru |
                    Add-Member -NotePropertyName "SPNApplicationAuthenticationClientSignInActivity" -NotePropertyValue $aacsia -PassThru | 
                    Add-Member -NotePropertyName "SPNApplicationAuthenticationResourceSignInActivity" -NotePropertyValue $aarsia -PassThru |
                    Add-Member -NotePropertyName "SPNDelegatedClientSignInActivity" -NotePropertyValue $DCSIA -PassThru |
                    Add-Member -NotePropertyName "SPNDelegatedResourceSignInActivity" -NotePropertyValue $drsia -PassThru 
}
else{write-host "NULL Date for " $item.displayname}
}