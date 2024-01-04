# written by debaxter
# 1/4/24
# 
# Used this script to check if the MSOL service used for ADConnect and see if the correct permissions have been set on the users for SSPR/Password writeback
# Checks for the following permissions and writes to the file
# Change Password, Reset Password, pwdLastSet, and lockoutTime have been set for the MSOL Service.
# run on a server with RSATs AD Directory Module for Windows Powershell installed
#
<#
 Parameters
 -dn "distinguishedname" (if not entered the forest level will be used connected to) and ALL OUs will be scanned
 -outputfile "file" or "c:\temp\file"
 -adcserviceprincipal "MSOL" (or the Name of your service principal if MSOL default is not used)
 -permissionscheck Inheritance - checks if inheritance has been disabled
 -permissionscheck "Entra Connect Service Account" checks if the 6 minimum permissions are set

By user
All users (no -dn entered)
Checking MSOL Entra/AD Connect Permissions
.\EntraIDConnectPermissionsInheritanceChecker.ps1 -OUorUser User -outputfile 1424-3 -PermissionsCheck 'Entra Connect Service Account' -adcserviceprincipal MSOL_xxxxyyyyzzzz
Checking Inheritance on user objects
.\EntraIDConnectPermissionsInheritanceChecker.ps1 -OUorUser User -outputfile 1424-3 -PermissionsCheck Inheritance -adcserviceprincipal MSOL_xxxxyyyyzzzz

Check specific user 
.\EntraIDConnectPermissionsInheritanceChecker.ps1 -OUorUser User -outputfile 1424-3 -PermissionsCheck 'Entra Connect Service Account' -adcserviceprincipal MSOL_e6873bfc57bd -dn "CN=R2 D3,OU=users,OU=Sales,OU=corp,DC=synclab,DC=local"
DN :  CN=R2 D3,OU=users,OU=Sales,OU=corp,DC=synclab,DC=local

Check specific users inheritance is disabled - if no file, then no permissions are found
.\EntraIDConnectPermissionsInheritanceChecker.ps1 -OUorUser User -outputfile 1424-3 -PermissionsCheck Inheritance -adcserviceprincipal MSOL_e6873bfc57bd -dn "CN=R2 D3,OU=users,OU=Sales,OU=corp,DC=synclab,DC=local"
DN :  CN=R2 D3,OU=users,OU=Sales,OU=corp,DC=synclab,DC=local

  By OU level to pull all users under an OU for Entra Connect Permissions
 Searching on a user to see if they have the correct permissions for Entra Connect
 .\EntraIDConnectPermissionsInheritanceChecker.ps1.ps1 -dn "OU=corp,DC=synclab,DC=local" -PermissionsCheck 'Entra Connect Service Account' -outputfile output.csv -adcserviceprincipal MSOL_xxxxyyyyzzzz
 
 Searching on a user to see if they have the correct permissions for Inheritance Disabled
.\EntraIDConnectPermissionsInheritanceChecker.ps1.ps1 -dn "OU=corp,DC=synclab,DC=local" -PermissionsCheck Inheritance -outputfile output.csv -adcserviceprincipal MSOL_xxxxyyyyzzzz
Unsure of the MSOL full account name - just use MSOL or NOTHING
.\EntraIDConnectPermissionsInheritanceChecker.ps1.ps1 -dn "OU=corp,DC=synclab,DC=local" -PermissionsCheck Inheritance -outputfile output.csv -adcserviceprincipal MSOL
.\EntraIDConnectPermissionsInheritanceChecker.ps1.ps1 -dn "OU=corp,DC=synclab,DC=local" -PermissionsCheck Inheritance -outputfile output.csv 

#>


param([Parameter(Mandatory=$False)][string]$dn,
      [parameter(Mandatory)][validateset("OU","User")][string]$OUorUser,  
      [parameter(Mandatory=$False)][validateset("Inheritance","Entra Connect Service Account")][string]$PermissionsCheck,  
      [parameter(Mandatory)][string]$outputfile,
      [parameter(Mandatory=$False)][string]$adcserviceprincipal) #typically starts with MSOL unless using a user/service account/gma


Import-Module activedirectory

if (!$dn){$dn = (get-addomain).DistinguishedName}
if (!$PermissionsCheck) {$PermissionsCheck = "Inheritance"}
if (!$adcserviceprincipal) {$adcserviceprincipal = "MSOL"}
write-host "DN : " $dn
write-host "PermissionsCheck : " $PermissionsCheck
write-host "outputfile : " $outputfile
write-host "adcserviceprincipal : " $adcserviceprincipal
$tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"

if($OUorUser -eq "User") #User Selected
{
    $adusers = (get-aduser -filter "*" -SearchBase $dn).DistinguishedName
    $acls =@()
    $exportacls =@()
    $exportinheritancecheck =@()

    if($PermissionsCheck -eq "Inheritance")
    {
        foreach ($item in $adusers) 
        {
            [string]$userdn = $item #.DistinguishedName
            $Objectinheritance = Get-ADUser -SearchBase "$userdn" -Filter * -Properties nTSecurityDescriptor
            $ntsec = $Objectinheritance.ntsecuritydescriptor.AreAccessRulesProtected
            $exportinheritancecheck += New-Object object |
                Add-Member -NotePropertyName DN -NotePropertyValue $Objectinheritance.DistinguishedName -PassThru |
                Add-Member -NotePropertyName InheritanceDisabled -NotePropertyValue $ntsec -PassThru
        }
        $filename2 = $OUorUser+$PermissionsCheck+"_Check_"+ $outputfile + "_"+$tdy +".csv"
        $exportfile = $exportinheritancecheck | Where-Object{$_.inheritancedisabled -eq "True"} 
        $exportfile | ft
        $exportfile  | export-csv -path $filename2 -NoTypeInformation -Force -Encoding UTF8
    }
    else #"Entra Connect Service Account" selected
    {
        [string]$holduser
        #if($UserorGroup -eq "User")
            #{
                $foundacl = @()
                foreach ($user in $adusers)
                    {
                    [string]$holduser = $user
                    #$acls = & dsacls $holduser | findstr "$adcserviceprincipal" 
                    $acls = & dsacls $holduser | select-string "$adcserviceprincipal" 
                    foreach ($foundacl in $acls)
                        {
                            if($foundacl -match "pwdLastSet" -or $foundacl -match"lockoutTime" -or $foundacl -match"Change Password"-or $foundacl -match"Reset Password" -or $foundacl -match "mS-DS-ConsistencyGuid" -or  $foundacl -match "msDS-KeyCredential")
                                {
                                    $exportacls += New-Object object |
                                        Add-Member -NotePropertyName User -NotePropertyValue $user -PassThru |
                                        Add-Member -NotePropertyName ACL -NotePropertyValue $foundacl -PassThru
                                }
                        }
                    }
           # }
            #$exportacls | Sort-Object User, missingACL | ft
        $filename = $OUorUser+$PermissionsCheck+ $outputfile + "_"+ $tdy +".csv"
        $exportacls | ft
        $exportacls | export-csv -path $Filename -NoTypeInformation -Force
    }
}
else # "OU" selected
{
    $checkOUPerm = dsacls  $dn | select-string $adcserviceprincipal
    #$checkOUPerm
    write-host "In forest check"
    write-host "Checking : " $dn 

    $foundForestDN = @()
    $foundOU = @()
    foreach($OUItem in $checkOUPerm)
    {
        if($OUItem -match "pwdLastSet" -or $OUItem -match"lockoutTime" -or $OUItem -match"Change Password"-or $OUItem -match"Reset Password" -or $OUItem -match "mS-DS-ConsistencyGuid" -or  $OUItem -match "msDS-KeyCredential")
            {
              $foundOU += New-Object object |
                Add-Member -NotePropertyName DistinguishedName -NotePropertyValue $dn -PassThru |
                Add-Member -NotePropertyName ACL -NotePropertyValue $ouitem -PassThru
            }
    }

    $allOUs = Get-ADOrganizationalUnit -Filter * | select distinguishedname
    write-host "In OU check"
    foreach($OUFound in $allOUs)
    {


        write-host "Checking OU : " $oufound.distinguishedname
        $findOUACLs = dsacls $OUFound.distinguishedname | select-string $adcserviceprincipal    
        foreach($OUItem in $findOUACLs)
        {
            if($OUItem -match "pwdLastSet" -or $OUItem -match"lockoutTime" -or $OUItem -match"Change Password"-or $OUItem -match"Reset Password" -or $OUItem -match "mS-DS-ConsistencyGuid" -or  $OUItem -match "msDS-KeyCredential")
                {
                    $foundOU += New-Object object |
                    Add-Member -NotePropertyName DistinguishedName -NotePropertyValue $OUFound.distinguishedname -PassThru |
                    Add-Member -NotePropertyName ACL -NotePropertyValue $OUItem -PassThru
                }
        }
    }
    $filename2 = "OU_Check_"+ $outputfile + "_"+$tdy +".csv"
    $exportfoundOUs = $foundOU | ?{$_.ACL -notmatch "<Inherited from parent>"}
    $exportfoundOUs| export-csv -Path $filename2 -NoTypeInformation -Force -Encoding UTF8
}