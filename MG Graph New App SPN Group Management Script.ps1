# Created 4/25/2022
# written by Debaxter
# how to create a new application and service principal to be able to login and manage group memberships
# using azure mg graph api

connect-mggraph -Scopes "Directory.ReadWrite.All, Application.Read.All, Application.ReadWrite.All, RoleManagement.ReadWrite.Directory"

New-mgApplication -DisplayName "MGAddGroupSPN" -IdentifierUris https://mgspn.domain.space
$MyApp = Get-MgApplication -Filter "Displayname eq 'MGAddGroupSPN'"
$myapp | select Id, appid

#Id                                   AppId
#--                                   -----
#d3382446-xxxx-yyyy-zzzz-aaaabbbbcccc 719520c8- xxxx-yyyy-zzzz-aaaabbbbcccc

New-MgServicePrincipal -appid $myapp.AppId
$SPNID = Get-MgServicePrincipal -Filter "DisplayName eq 'MGAddGroupSPN'"
$spnid | select id, appid, displayname

#Id                                   AppId                                DisplayName
#--                                   -----                                -----------
#a4cc78cf-xxxx-yyyy-zzzz-aaaabbbbcccc 719520c8-xxxx-yyyy-zzzz-aaaabbbbcccc MGAddGroupSPN
      
Assigning the “Directory Reader Role” to the new service principal
NOTE! This is a MUST
#Assigning the “Directory Reader Role” to the new service principal
$DRoID = Get-MgDirectoryRole | ?{$_.DisplayName -match "Directory Reader"}

#add directory reader role to SPN

#User the applications objectid
$DirObject = @{
  "@odata.id" = https://graph.microsoft.com/v1.0/directoryObjects/a4cc78cf-xxxx-yyyy-zzzz-aaaabbbbcccc
  }

New-MgDirectoryRoleMemberByRef -DirectoryRoleId $DRoID.Id -BodyParameter $DirObject

#(Add the API permissions and certificate to the new service principal)
 
#AzureAD portal\apps registration\All and locate the app - Application
# Api permissions + Add Permission \ Graph \ Application Permissions
# Directory.ReadWrite.All
# Group.Read.All
# Group.ReadWrite.All
# GroupMember.Read.All
# GroupMember.ReadWrite.All
#
# Under Certificate - Add the PEM certificate for the service principal 

# Within your script

Connect-MgGraph -ClientId "719520c8-xxxx-yyyy-zzzz-aaaabbbbcccc" -TenantId "7b69d5f1-xxxx-yyyy-zzzz-aaaabbbbcccc " -CertificateThumbprint "Thumbprint" 

# To add a user to a group
new-mggroupmember -GroupId (Get-MgGroup -Filter "Displayname eq 'MyGroup'").id -DirectoryObjectId (Get-MgUser -Filter "Displayname eq 'First Last'").Id 

# To add a service principal
new-mggroupmember -GroupId (Get-MgGroup -Filter "Displayname eq 'MyGroup'").id -DirectoryObjectId (Get-MgServicePrincipal -Filter "Displayname eq 'OtherSPN'").Id 