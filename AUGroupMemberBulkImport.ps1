<#
Written by Derrick Baxter 10/31/23
For bulk import of group members to restricted management Administrative Unit

CSV created gm.csv saved in c:\temp
groupmemberobjectid
"6674bd59-d010-4a9c-b0ed-d2c3f786c677"
"eb9f7358-6b92-4bc9-b2e4-699a9fa97185"


.\augroupMemberImport.ps1 -importfile c:\temp\gm.csv -groupobjectid "b1f92b75-groupoid-guid"
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