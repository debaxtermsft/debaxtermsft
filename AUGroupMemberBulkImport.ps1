<#
Written by Derrick Baxter 10/31/23
For bulk import of group members to restricted management Administrative Unit

CSV created gm.csv saved in c:\temp
groupmemberobjectid
"6674bd59-d010-4a9c-b0ed-d2c3f786c677"
"eb9f7358-6b92-4bc9-b2e4-699a9fa97185"
.\augroupMemberImport.ps1 -importfile c:\temp\gm.csv -groupobjectid "b1f92b75-groupoid-guid"


Each user will need a GA to run the below script to grant consent to Microsoft Graph
#----------------------- consent script start ----------------
$sp = get-mgserviceprincipal | ?{$_.displayname -eq "Microsoft Graph"}
$resource = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$principalid = "users object id" # look up and add the users object id here between the quotes
$scope1 ="directory.write.restricted"
$scope2 ="directory.read.all"
$scope3 ="group.read.all"
$scope4 ="groupmember.readwrite.all"

$params = @{
    ClientId = $SP.Id
    ConsentType = "Principal"
    ResourceId = $resource.id
    principalId = $principalid
    Scope = "$scope1" + " " + "$scope2"+ " " + "$scope3"+ " " + "$scope4"
}
$InitialConsented = New-MgOauth2PermissionGrant -BodyParameter $params
#----------------------- consent script end ----------------

#>

---- AU bulk member import via powershell
param([parameter(mandatory=$false)][string] $tenantID,
            [parameter (mandatory=$true)][string]$importfile,
            [parameter(mandatory=$true)]$groupobjectid)
            


try
    {
    Get-MGDomain -ErrorAction Stop > $null
    }
catch
    {
       if($tenentID -eq $null)
       {
            connect-mggraph -scopes "directory.read.all, group.read.all, groupmember.readwrite.all,directory.write.restricted"
        }
        else
        {
            connect-mggraph -scopes "directory.read.all, group.read.all, groupmember.readwrite.all,directory.write.restricted" -tenantid $tenantID
        }

    }

$groupmembersimport = import-csv -path $importfile

foreach($gitem in $groupmembersimport)
{
    New-MgGroupMember -GroupId $groupobjectid -DirectoryObjectId $gitem.Groupmemberobjectid

}