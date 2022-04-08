# written by debaxter
# 4/8/22
# 
# Used this script to check if the MSOL service used for ADConnect and see if the correct permissions have been set on the users for SSPR/Password writeback
# Checks for the following permissions and writes to the file
# Change Password, Reset Password, pwdLastSet, and lockoutTime have been set for the MSOL Service.
# run on a server with RSATs AD Directory Module for Windows Powershell installed
#
#
# Parameters
# -dn "distinguishedname"
# -outputfile "file.csv" or "c:\temp\file.csv"
#
#
# By OU level to pull all users under an OU
# PS C:\temp\.\adconnectpermssions.ps1 -dn “OU=corp,DC=domain,DC=local” -outputfile “.\adconnectMSOLpermissions.csv”
#
# Searching on a user to see if they have the correct permissions 
# PS C:\temp\.\adconnectpermssions.ps1 -dn “CN=Morty Smith,OU=users, OU=Sales,OU=corp,DC=domain,DC=local” -outputfile “.\adconnectMSOLpermissions.csv”
#


param([parameter(mandatory)][string]$dn,
      [parameter(mandatory)][string]$outputfile)

Import-Module activedirectory

$adusers = (get-aduser -filter "*" -SearchBase $dn).DistinguishedName
#$adusers = (get-aduser -filter "*" -SearchBase "OU=corp,DC=twdsynclab,DC=local").DistinguishedName
$acls =@()
$exportacls =@()
[string]$holduser

foreach ($user in $adusers)
{
[string]$holduser = $user
$acls = & dsacls $holduser | findstr "MSOL"
foreach ($foundacl in $acls)
    {
        if($foundacl -match "pwdLastSet" -or $foundacl -match"lockoutTime" -or $foundacl -match"Change Password"-or $foundacl -match"Reset Password")
        {
        #write-host $user "has" $foundacl
        $exportacls += New-Object object |
            Add-Member -NotePropertyName User -NotePropertyValue $user -PassThru |
            Add-Member -NotePropertyName ACL -NotePropertyValue $foundacl -PassThru
        }
    }
}
$exportacls | ft
$exportacls | export-csv -path $outputfile -NoTypeInformation -Force
