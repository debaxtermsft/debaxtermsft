<# 
Written by Derrick Baxter
3/5/2024
Run on a DC or DC accessible domain joined machine
Used for customers wanting to be able to check the lastlogondate and lastlogontimestamp values to see if users have not signed in locally for a long time
Can be used in combination with scripts in this repository commercial_graphapi_signinactivity for AAD
Compare AD and AAD signin/logon activity
Modify the .addddays(-30) to the number of days back you need to check if a user has not logged in


#>
param([parameter(Position=0,mandatory=$false)][int]$DaysBack,
      [parameter(Position=1,mandatory)] [string]$Outputdirectory)

If($DaysBack -eq $null) #if no daysback is entered -30 used
{
    $DaysBack = -30
}
elseif($daysback -gt 0) #making sure entered days back is negative
{
    $daysback = 0 - $daysback
}
# where-object filter setup to not pull accounts without userprincipalnames 
# DN added as service account and accounts without UPN are typically not needed.  
#remove -and $_.userprincipalname -ne $null if you want ALL Accounts onprem
$adusers = get-aduser -filter * -properties * | Where-Object {$_.lastlogondate -ge (get-date).adddays(-30) -and $_.userprincipalname -ne $null} | select displayname,userprincipalname,DistinguishedName, LastLogonDate, lastLogonTimestamp
$lastLogonTimestampProperties =@()

foreach($item in $adusers)
{
    $edtime = w32tm.exe /ntte $item.lastLogonTimestamp
    $splittime = $edtime -split " - ",2
    $tdy = $splittime[1]
    write-host $item.DistinguishedName "," $item.userprincipalname "," $item.lastlogondate "," $tdy 

    $lastLogonTimestampProperties += New-Object Object |
                                    Add-Member -NotePropertyName DistinguishedName -NotePropertyValue $item.DistinguishedName -PassThru |
                                    Add-Member -NotePropertyName displayname -NotePropertyValue $item.displayname -PassThru |
                                    Add-Member -NotePropertyName userPrincipalname -NotePropertyValue $item.userprincipalname -PassThru |
                                    Add-Member -NotePropertyName LastLogonDate -NotePropertyValue $item.lastlogonDate -PassThru |
                                    Add-Member -NotePropertyName lastLogonTimestamp -NotePropertyValue $item.lastLogonTimestampProperties -PassThru
}
$tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
$file = $outputdirectory +"OnPremAD_LastLogonTimestamp_"+$tdy+".csv"
$lastLogonTimestampProperties | export-csv -path $file -NoTypeInformation -Encoding UTF8