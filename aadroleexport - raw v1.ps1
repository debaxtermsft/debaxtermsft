<#
 the below script uses the AzureAD powershell module pulling all roleassignments for groups
10/11/23
# updates 
# written by debaxter
#>

try
    {
    Get-AzureADDomain -ErrorAction Stop > $null
    }
catch
    {
    connect-azuread
    }
    
$members =@()
$roleassignments = Get-AzureADMSRoleAssignment -All $true | sort-object principalid -Unique

foreach($roleassignmentitem in $roleassignments)
{
	$objecttypeproperty = Get-AzureADObjectByObjectId -objectid $roleassignmentitem.PrincipalId
	$roledefinitionnameitem = Get-AzureADMSRoleDefinition -Id $roleassignmentitem.RoleDefinitionId | select displayname

	if ($objecttypeproperty.objecttype -eq "User")
	{
		$dirobject = get-azureaduser -objectid $roleassignmentitem.PrincipalId
	}
	elseif ($objecttypeproperty.objecttype -eq "Group")
	{
		$dirobject = get-azureadgroup -objectid $roleassignmentitem.PrincipalId
	}
	else
	{
		$dirobject = Get-AzureADServicePrincipal -ObjectId  $roleassignmentitem.PrincipalId
	}

	$members += New-Object Object |
											Add-Member -NotePropertyName DisplayName -NotePropertyValue $dirobject.displayname -PassThru |
											Add-Member -NotePropertyName UserPrincipalName -NotePropertyValue $dirobject.userprincipalname -PassThru |
											Add-Member -NotePropertyName ObjectID -NotePropertyValue $dirobject.objectid -PassThru |
											Add-Member -NotePropertyName AADRoleName -NotePropertyValue $roledefinitionnameitem -PassThru |
											Add-Member -NotePropertyName AADRoleObjectID -NotePropertyValue $roleassignmentitem.ObjectID -PassThru |
											Add-Member -NotePropertyName AADObjectType -NotePropertyValue $dirobject.ObjectType -PassThru |
											Add-Member -NotePropertyName AADRoleAssignmentID -NotePropertyValue $roleassignmentitem.RoleDefinitionId -PassThru |
											Add-Member -NotePropertyName AADDirectoryScopeID -NotePropertyValue $roleassignmentitem.DirectoryScopeId -PassThru
}

$members | export-csv -path c:\temp\aadroleexport.csv -notypeinformation