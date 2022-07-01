# this script will convert an Azure user to a B2B user and send an email invitation to the new email address
# you will need to create a csv file (bulkupdate.csv)
# the csv will need to be formatted exactly like this
#userid,mail
#usersobjectid1,user1@domain.com
#usersobjectid.,user2@domain.com
#usersobjectidN,userN@domain.com
# you can use excel or your favorite text editor, but needs to be saved as a CSV
# created 7/1/2022
# written by Derrick Baxter


Connect-AzureAD
Connect-AzAccount
$usermailupdate = import-csv -Path "c:\temp\bulkupdate.csv" -Delimiter ","

foreach($item in $usermailupdate)
{
    Update-azADUser -ObjectId $item.userid -Mail $item.mail

}
foreach($item2 in $usermailupdate)
{
    $ADGraphUser = Get-AzureADUser -objectID $item.userid
    $msGraphUser = New-Object Microsoft.Open.MSGraph.Model.User -ArgumentList $ADGraphUser.ObjectId
    New-AzureADMSInvitation -InvitedUserEmailAddress $item.mail -SendInvitationMessage $True -InviteRedirectUrl "http://myapps.microsoft.com" -InvitedUser $msGraphUser
}

